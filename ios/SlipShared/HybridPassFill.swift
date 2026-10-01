import Foundation

#if canImport(FoundationModels)
import FoundationModels
#endif

/// Hybrid extraction: Vision/regex lock rigid identifiers; Apple Intelligence fills fuzzy gaps only.
/// AI baseline is iOS 27 Apple Intelligence (`FoundationModels`) — no third-party LLM APIs.
enum HybridPassFill {
    /// Keys that must never be invented or overwritten by generative models.
    static let anchorKeys: Set<String> = [
        "qr_data", "pnr", "booking_id", "coach", "train", "flight",
        "ifsc", "vpa", "upi_id", "plate", "vehicle_reg", "member_id", "membership"
    ]

    /// Semantic / layout-fuzzy keys safe for targeted on-device LLM fill when empty.
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

    /// Stage C: fill only empty fuzzy keys via on-device Apple Intelligence (iOS 27+).
    static func fillMissingFuzzy(
        templateId: String,
        fields: [String: String],
        ticket: ExtractedTicket
    ) async -> [String: String] {
        let missing = missingFuzzyKeys(in: fields, templateId: templateId)
        guard !missing.isEmpty else { return fields }

        var merged = fields
        #if canImport(FoundationModels)
        if #available(iOS 27.0, *) {
            if let filled = await FoundationFuzzyFiller.fill(
                templateId: templateId,
                missingKeys: missing,
                ticket: ticket
            ) {
                applyFuzzy(filled, into: &merged, allowed: Set(missing))
            }
        }
        #endif
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
/// On-device Apple Intelligence fuzzy fill — iOS 27 Neural Engine / Private Cloud Compute only.
@available(iOS 27.0, *)
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
        // Larger local context window on iOS 27 — still clip for latency.
        let clipped = String(text.prefix(4500))
        let keyList = missingKeys.joined(separator: ", ")
        let brandHint = brandPrompt(for: templateId)

        let session = LanguageModelSession(instructions: """
            You extract missing Apple Wallet pass fields from Indian ticket / booking OCR.
            Privacy: run entirely on-device. Never invent identifiers.
            Template is already locked: \(templateId).
            Only fill: \(keyList).
            \(brandHint)
            Rules:
            - Prefer "" over guesses.
            - Never invent PNRs, booking IDs, QR/barcode payloads, IFSC, VPA, or plate numbers.
            - Seat lists stay as seat codes only (e.g. A5, B6) — never "SCREEN 2" alone.
            - Dining brands put the place name in restaurant, never event.
            - Theatre brands put the title in event, never restaurant.
            """)

        do {
            let response = try await session.respond(
                to: """
                Template: \(templateId)
                Extract ONLY these empty fields: \(keyList)

                Surrounding ticket text from Vision OCR (barcode payload intentionally omitted):
                \(clipped)
                """,
                generating: FuzzyPassDraft.self
            )
            return FuzzyPassDraft.asDictionary(response.content)
        } catch {
            return nil
        }
    }

    private static func brandPrompt(for templateId: String) -> String {
        switch templateId {
        case "bookmyshow", "district":
            return "Cinema/festival: event = movie or show title; venue = theatre; seat = seat codes."
        case "easydiner", "zomato-dineout", "swiggy-dineout":
            return "Dining: restaurant = venue name; party_size = guest count; time = reservation time."
        case "airbnb":
            return "Stay: property = listing title; guest = primary guest name."
        case "indigo", "makemytrip", "cleartrip", "yatra":
            return "Flight: origin/destination = airports; gate/seat when present in text."
        case "irctc", "redbus", "uts", "chalo":
            return "Transit: origin/destination stations; passenger name; seat/coach when present."
        case "zoomcar", "uber", "ola":
            return "Vehicle/ride: vehicle model; pickup and drop_off places."
        default:
            return "Use empty strings when the OCR does not clearly state a value."
        }
    }
}

@available(iOS 27.0, *)
@Generable(description: "Fuzzy semantic Wallet fields only — never QR, PNR, or booking IDs")
struct FuzzyPassDraft {
    @Guide(description: "Movie or show title for BookMyShow/District")
    var event: String?

    @Guide(description: "Restaurant name for dining brands")
    var restaurant: String?

    @Guide(description: "Cinema or venue name")
    var venue: String?

    @Guide(description: "Airbnb / stay property title")
    var property: String?

    @Guide(description: "Guest or reserved-for name")
    var guest: String?

    @Guide(description: "Passenger name for trains/flights/buses")
    var passenger: String?

    @Guide(description: "Car or vehicle model")
    var vehicle: String?

    @Guide(description: "Pickup location text")
    var pickup: String?

    @Guide(description: "Drop-off location text")
    var dropOff: String?

    @Guide(description: "Showtime or reservation time")
    var time: String?

    @Guide(description: "Party size as a number string, e.g. 2")
    var partySize: String?

    @Guide(description: "Boarding or festival gate")
    var gate: String?

    @Guide(description: "Origin station or airport")
    var origin: String?

    @Guide(description: "Destination station or airport")
    var destination: String?

    @Guide(description: "Bus service name if present")
    var bus: String?

    @Guide(description: "Payee or member display name")
    var name: String?

    @Guide(description: "Seat codes only, e.g. A5, B6 — never SCREEN N alone")
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
