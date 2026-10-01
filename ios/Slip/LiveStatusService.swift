import ActivityKit
import Foundation

/// Optional live flight/train status → Live Activity updates.
/// Uses AviationStack when `slip.aviation.apiKey` is set; otherwise no-ops.
@MainActor
enum LiveStatusService {
    static let apiKeyDefaultsKey = "slip.aviation.apiKey"

    static var apiKey: String? {
        let raw = UserDefaults.standard.string(forKey: apiKeyDefaultsKey)
            ?? UserDefaults(suiteName: SharedInbox.appGroupId)?.string(forKey: apiKeyDefaultsKey)
            ?? Bundle.main.object(forInfoDictionaryKey: "SlipAviationAPIKey") as? String
            ?? ""
        let t = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? nil : t
    }

    static func refreshActivePasses(from vault: PassVaultStore) async {
        guard apiKey != nil else { return }
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
        guard let apiKey else { return nil }
        if payload.templateId == "indigo" {
            let flight = (payload.fields["flight"] ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            guard !flight.isEmpty else { return nil }
            // AviationStack realtime flights by flight_iata (e.g. 6E234).
            let iata = flight.uppercased().replacingOccurrences(of: " ", with: "")
            guard let url = URL(string: "https://api.aviationstack.com/v1/flights?access_key=\(apiKey)&flight_iata=\(iata)&limit=1") else {
                return nil
            }
            do {
                let (data, response) = try await URLSession.shared.data(from: url)
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
                return StatusUpdate(status: "\(iata) · \(status)", detail: detailParts.isEmpty ? "Live tracking" : detailParts.joined(separator: " · "))
            } catch {
                return nil
            }
        }

        // IRCTC: no free public realtime API — surface scheduled detail only.
        if payload.templateId == "irctc" {
            let train = payload.fields["train"] ?? "Train"
            let coach = payload.fields["coach"]
            let seat = payload.fields["seat"]
            let detail = [coach.map { "Coach \($0)" }, seat.map { "Berth \($0)" }].compactMap { $0 }.joined(separator: " · ")
            return StatusUpdate(status: train, detail: detail.isEmpty ? "On-time (scheduled)" : detail)
        }
        return nil
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
