import Foundation

#if canImport(FoundationModels)
import FoundationModels
#endif

/// Hybrid extraction helpers: deterministic anchors stay locked; LLMs only fill fuzzy gaps.
enum HybridPassFill {
    /// Keys that must never be invented or overwritten by generative models.
    static let anchorKeys: Set<String> = [
        "qr_data", "pnr", "booking_id", "coach", "train", "flight",
        "ifsc", "vpa", "upi_id", "plate", "vehicle_reg", "member_id", "membership"
    ]

    /// Semantic / layout-fuzzy keys safe for targeted LLM fill when empty.
    static let fuzzyKeys: Set<String> = [
        "event", "restaurant", "venue", "property", "guest", "passenger",
        "vehicle", "pickup", "drop_off", "time", "party_size", "gate", "seat",
        "origin", "destination", "bus", "name"
    ]

    static func normalizeBrand(_ raw: String) -> String {
        let t = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let aliases: [String: String] = [
            "bms": "bookmyshow", "book my show": "bookmyshow", "cinema": "bookmyshow",
            "6e": "indigo", "indi go": "indigo", "indigo airlines": "indigo",
            "rail": "irctc", "train": "irctc", "indian railways": "irctc",
            "eazy diner": "easydiner", "easydiner": "easydiner",
            "zomato": "zomato-dineout", "zomato dineout": "zomato-dineout",
            "swiggy": "swiggy-dineout", "dineout": "swiggy-dineout", "swiggy dineout": "swiggy-dineout",
            "metro": "namma-metro", "namma metro": "namma-metro",
            "red bus": "redbus", "zoom": "zoomcar", "zoom car": "zoomcar",
            "sunburn": "district", "boiler room": "district"
        ]
        if let mapped = aliases[t] { return mapped }
        let allowed = [
            "irctc", "bookmyshow", "indigo", "district", "easydiner", "zomato-dineout",
            "swiggy-dineout", "airbnb", "namma-metro", "upi", "redbus", "zoomcar", "cult"
        ]
        if allowed.contains(t) { return t }
        if t.contains("metro") { return "namma-metro" }
        if t.contains("indigo") { return "indigo" }
        if t.contains("irctc") || t.contains("rail") { return "irctc" }
        if t.contains("eazy") { return "easydiner" }
        if t.contains("zomato") { return "zomato-dineout" }
        if t.contains("swiggy") { return "swiggy-dineout" }
        if t.contains("airbnb") { return "airbnb" }
        if t.contains("redbus") { return "redbus" }
        if t.contains("zoom") { return "zoomcar" }
        if t.contains("district") || t.contains("sunburn") { return "district" }
        if t.contains("book") || t.contains("cinema") || t.contains("inox") { return "bookmyshow" }
        if t.contains("upi") { return "upi" }
        if t.contains("cult") { return "cult" }
        return ""
    }

    /// Lock Vision QR + regex anchors so generative fill cannot rewrite them.
    static func lockAnchors(into fields: inout [String: String], ticket: ExtractedTicket, rules: ClassificationResult) {
        for key in anchorKeys {
            if let v = rules.fields[key]?.trimmingCharacters(in: .whitespacesAndNewlines), !v.isEmpty {
                fields[key] = v
            }
        }
        if let qr = ticket.qrPayload?.trimmingCharacters(in: .whitespacesAndNewlines), !qr.isEmpty {
            fields["qr_data"] = qr
        } else if let qr = rules.fields["qr_data"]?.trimmingCharacters(in: .whitespacesAndNewlines), !qr.isEmpty {
            fields["qr_data"] = qr
        }
    }

    static func missingFuzzyKeys(in fields: [String: String], templateId: String) -> [String] {
        let schemaKeys = BrandFields.schema(for: templateId).allowed
        let candidates = fuzzyKeys.intersection(schemaKeys.isEmpty ? fuzzyKeys : schemaKeys)
        return candidates.sorted().filter { key in
            let v = fields[key]?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            return v.isEmpty
        }
    }

    /// Stage C: fill only empty fuzzy fields via on-device model, then optional Gemini.
    static func fillMissingFuzzy(
        templateId: String,
        fields: [String: String],
        ticket: ExtractedTicket
    ) async -> [String: String] {
        let missing = missingFuzzyKeys(in: fields, templateId: templateId)
        guard !missing.isEmpty else { return fields }

        var merged = fields
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            if let filled = await FoundationFuzzyFiller.fill(
                templateId: templateId,
                missingKeys: missing,
                ticket: ticket
            ) {
                applyFuzzy(filled, into: &merged, allowed: Set(missing))
            }
        }
        #endif

        let stillMissing = missingFuzzyKeys(in: merged, templateId: templateId)
        if !stillMissing.isEmpty,
           let filled = await GeminiFuzzyFiller.fill(
            templateId: templateId,
            missingKeys: stillMissing,
            ticket: ticket
           ) {
            applyFuzzy(filled, into: &merged, allowed: Set(stillMissing))
        }
        return merged
    }

    private static func applyFuzzy(_ source: [String: String], into fields: inout [String: String], allowed: Set<String>) {
        for (key, value) in source {
            guard allowed.contains(key), !anchorKeys.contains(key) else { continue }
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }
            let existing = fields[key]?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if existing.isEmpty {
                fields[key] = trimmed
            }
        }
    }
}

#if canImport(FoundationModels)
@available(iOS 26.0, *)
enum FoundationFuzzyFiller {
    static var isAvailable: Bool {
        if case .available = SystemLanguageModel.default.availability {
            return true
        }
        return false
    }

    static func fill(
        templateId: String,
        missingKeys: [String],
        ticket: ExtractedTicket
    ) async -> [String: String]? {
        guard isAvailable, !missingKeys.isEmpty else { return nil }

        let text = ticket.recognizedText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard text.count >= 12 else { return nil }
        let clipped = String(text.prefix(2800))
        let keyList = missingKeys.joined(separator: ", ")

        let session = LanguageModelSession(instructions: """
            You fill missing Apple Wallet pass fields for Indian tickets.
            Brand/template is already known: \(templateId).
            Only extract these keys: \(keyList).
            Prefer empty strings over guesses. Never invent PNRs, booking IDs, or QR payloads.
            Return JSON-shaped values via the schema only.
            """)

        do {
            let response = try await session.respond(
                to: """
                Known template: \(templateId)
                Missing fields to extract: \(keyList)

                Ticket text (OCR):
                \(clipped)
                """,
                generating: FuzzyPassDraft.self
            )
            return FuzzyPassDraft.asDictionary(response.content)
        } catch {
            return nil
        }
    }
}

@available(iOS 26.0, *)
@Generable(description: "Only fuzzy / semantic ticket fields — never identifiers or QR")
struct FuzzyPassDraft {
    var event: String?
    var restaurant: String?
    var venue: String?
    var property: String?
    var guest: String?
    var passenger: String?
    var vehicle: String?
    var pickup: String?
    var dropOff: String?
    var time: String?
    var partySize: String?
    var gate: String?
    var origin: String?
    var destination: String?
    var bus: String?
    var name: String?
    var seat: String?

    static func asDictionary(_ draft: FuzzyPassDraft) -> [String: String] {
        var out: [String: String] = [:]
        func put(_ key: String, _ value: String?) {
            let v = (value ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            if !v.isEmpty { out[key] = v }
        }
        put("event", draft.event)
        put("restaurant", draft.restaurant)
        put("venue", draft.venue)
        put("property", draft.property)
        put("guest", draft.guest)
        put("passenger", draft.passenger)
        put("vehicle", draft.vehicle)
        put("pickup", draft.pickup)
        put("drop_off", draft.dropOff)
        put("time", draft.time)
        put("party_size", draft.partySize)
        put("gate", draft.gate)
        put("origin", draft.origin)
        put("destination", draft.destination)
        put("bus", draft.bus)
        put("name", draft.name)
        put("seat", draft.seat)
        return out
    }
}
#endif

/// Optional cloud fallback when Apple Intelligence is unavailable. Key from App Group / Settings.
enum GeminiFuzzyFiller {
    static let apiKeyDefaultsKey = "slip.gemini.apiKey"

    static var apiKey: String? {
        let suite = UserDefaults(suiteName: SharedInbox.appGroupId)
        let raw = (suite?.string(forKey: apiKeyDefaultsKey)
            ?? UserDefaults.standard.string(forKey: apiKeyDefaultsKey)
            ?? Bundle.main.object(forInfoDictionaryKey: "SlipGeminiAPIKey") as? String)
            ?? ""
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    static func fill(
        templateId: String,
        missingKeys: [String],
        ticket: ExtractedTicket
    ) async -> [String: String]? {
        guard let apiKey, !missingKeys.isEmpty else { return nil }
        let text = ticket.recognizedText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard text.count >= 12 else { return nil }
        let clipped = String(text.prefix(2800))
        let keyList = missingKeys.joined(separator: ", ")

        let prompt = """
        Extract only these JSON keys from an Indian ticket (template \(templateId)): \(keyList).
        Return a single JSON object with those keys as strings. Use "" when unknown.
        Never invent booking IDs, PNRs, or QR codes. OCR text:
        \(clipped)
        """

        guard let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=\(apiKey)") else {
            return nil
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 12
        let body: [String: Any] = [
            "contents": [
                ["parts": [["text": prompt]]]
            ],
            "generationConfig": [
                "temperature": 0.1,
                "responseMimeType": "application/json"
            ]
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                return nil
            }
            guard let root = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let candidates = root["candidates"] as? [[String: Any]],
                  let content = candidates.first?["content"] as? [String: Any],
                  let parts = content["parts"] as? [[String: Any]],
                  let textOut = parts.first?["text"] as? String,
                  let jsonData = textOut.data(using: .utf8),
                  let parsed = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any]
            else { return nil }

            var out: [String: String] = [:]
            for key in missingKeys {
                if let s = parsed[key] as? String {
                    let t = s.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !t.isEmpty { out[key] = t }
                }
            }
            return out.isEmpty ? nil : out
        } catch {
            return nil
        }
    }
}
