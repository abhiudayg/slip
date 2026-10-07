import ActivityKit
import Foundation

/// Optional live flight/train status → Live Activity updates.
/// Flights use AviationStack when `slip.aviation.apiKey` is set.
/// IRCTC surfaces coach/berth + schedule window without a third-party key;
/// optional `slip.rail.apiURL` can point at a self-hosted train-status proxy.
@MainActor
enum LiveStatusService {
    static let apiKeyDefaultsKey = "slip.aviation.apiKey"
    static let railProxyDefaultsKey = "slip.rail.apiURL"

    static var apiKey: String? {
        let raw = UserDefaults.standard.string(forKey: apiKeyDefaultsKey)
            ?? UserDefaults(suiteName: SharedInbox.appGroupId)?.string(forKey: apiKeyDefaultsKey)
            ?? Bundle.main.object(forInfoDictionaryKey: "SlipAviationAPIKey") as? String
            ?? ""
        let t = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? nil : t
    }

    static var railProxyURL: String? {
        let raw = UserDefaults.standard.string(forKey: railProxyDefaultsKey)
            ?? UserDefaults(suiteName: SharedInbox.appGroupId)?.string(forKey: railProxyDefaultsKey)
            ?? ""
        let t = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? nil : t
    }

    static func refreshActivePasses(from vault: PassVaultStore) async {
        for record in vault.records where !record.isExpired {
            guard let payload = try? vault.decrypt(record) else { continue }
            guard payload.templateId == "indigo" || payload.templateId == "irctc" else { continue }
            if let update = await fetchStatus(for: payload) {
                await PassLiveActivityController.updateMatching(
                    templateId: payload.templateId,
                    statusLine: update.status,
                    detailLine: update.detail
                )
            }
        }
    }

    private struct StatusUpdate {
        var status: String
        var detail: String
    }

    private static func fetchStatus(for payload: PassVaultPayload) async -> StatusUpdate? {
        if payload.templateId == "indigo" {
            guard let apiKey else { return nil }
            let flight = (payload.fields["flight"] ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            guard !flight.isEmpty else { return nil }
            let iata = flight.uppercased().replacingOccurrences(of: " ", with: "")
            guard let url = URL(string: "https://api.aviationstack.com/v1/flights?flight_iata=\(iata)&limit=1") else {
                return nil
            }
            var req = URLRequest(url: url)
            req.setValue(apiKey, forHTTPHeaderField: "X-Api-Key")
            do {
                let (data, response) = try await URLSession.shared.data(for: req)
                guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else { return nil }
                guard let root = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let list = root["data"] as? [[String: Any]],
                      let first = list.first else { return nil }
                let dep = first["departure"] as? [String: Any]
                let gate = (dep?["gate"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
                let delay = dep?["delay"] as? Int
                let status = (first["flight_status"] as? String)?.capitalized ?? "In progress"
                var detailParts: [String] = []
                if let gate, !gate.isEmpty { detailParts.append("Gate \(gate)") }
                if let delay, delay > 0 { detailParts.append("Delayed \(delay)m") }
                if let seat = payload.fields["seat"], !seat.isEmpty { detailParts.append("Seat \(seat)") }
                return StatusUpdate(
                    status: "\(iata) · \(status)",
                    detail: detailParts.isEmpty ? "Live tracking" : detailParts.joined(separator: " · ")
                )
            } catch {
                return nil
            }
        }

        if payload.templateId == "irctc" {
            if let live = await fetchRailProxy(for: payload) {
                return live
            }
            let train = (payload.fields["train"] ?? payload.fields["train_number"] ?? "Train")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            let coach = payload.fields["coach"]
            let seat = payload.fields["seat"] ?? payload.fields["berth"]
            var detailParts: [String] = []
            if let coach, !coach.isEmpty { detailParts.append("Coach \(coach)") }
            if let seat, !seat.isEmpty { detailParts.append("Berth \(seat)") }
            if let pnr = payload.fields["pnr"], !pnr.isEmpty { detailParts.append("PNR \(pnr)") }
            return StatusUpdate(
                status: train.isEmpty ? "Train" : train,
                detail: detailParts.isEmpty ? "On-time (scheduled)" : detailParts.joined(separator: " · ")
            )
        }
        return nil
    }

    /// Optional self-hosted proxy: GET {base}?train=12345&date=YYYY-MM-DD → {status,detail}
    private static func fetchRailProxy(for payload: PassVaultPayload) async -> StatusUpdate? {
        guard let base = railProxyURL else { return nil }
        let train = (payload.fields["train"] ?? payload.fields["train_number"] ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !train.isEmpty else { return nil }
        var components = URLComponents(string: base)
        var items = components?.queryItems ?? []
        items.append(URLQueryItem(name: "train", value: train))
        if let iso = payload.relevantDateISO8601, iso.count >= 10 {
            items.append(URLQueryItem(name: "date", value: String(iso.prefix(10))))
        }
        components?.queryItems = items
        guard let url = components?.url else { return nil }
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else { return nil }
            guard let root = try JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
            let status = (root["status"] as? String) ?? train
            let detail = (root["detail"] as? String) ?? "Live"
            return StatusUpdate(status: status, detail: detail)
        } catch {
            return nil
        }
    }
}

extension PassLiveActivityController {
    static func updateMatching(templateId: String, statusLine: String, detailLine: String) async {
        for activity in Activity<SlipPassActivityAttributes>.activities where activity.attributes.templateId == templateId {
            let state = SlipPassActivityAttributes.ContentState(
                statusLine: statusLine,
                detailLine: detailLine,
                progress: min(1, activity.content.state.progress + 0.05)
            )
            let content = ActivityContent(state: state, staleDate: Date().addingTimeInterval(3600))
            await activity.update(content)
        }
    }
}
