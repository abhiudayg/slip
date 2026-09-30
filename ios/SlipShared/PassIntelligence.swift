import Foundation

#if canImport(FoundationModels)
import FoundationModels
#endif

/// On-device Apple Intelligence fill with regex BrandClassifier fallback.
enum IntelligentBrandClassifier {
    static func classify(_ ticket: ExtractedTicket) async -> ClassificationResult {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            if let filled = await FoundationPassFiller.fill(from: ticket) {
                return filled
            }
        }
        #endif
        return BrandClassifier.classify(ticket)
    }
}

#if canImport(FoundationModels)
@available(iOS 26.0, *)
enum FoundationPassFiller {
    static var isAvailable: Bool {
        if case .available = SystemLanguageModel.default.availability {
            return true
        }
        return false
    }

    static func fill(from ticket: ExtractedTicket) async -> ClassificationResult? {
        guard isAvailable else { return nil }

        let text = ticket.recognizedText.trimmingCharacters(in: .whitespacesAndNewlines)
        let qr = ticket.qrPayload?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard text.count >= 20 || !qr.isEmpty else { return nil }

        // Keep prompt small for on-device context window.
        let clipped = String(text.prefix(3500))
        let session = LanguageModelSession(instructions: """
            You extract Apple Wallet pass fields from Indian ticket / booking text.
            Choose templateId from: irctc, bookmyshow, indigo, easydiner, zomato-dineout, swiggy-dineout, airbnb, namma-metro, upi, redbus, zoomcar.
            Prefer empty strings over guesses. Never invent QR payloads.
            If a QR/barcode payload is provided, copy it into qrData unchanged.
            """)

        do {
            let response = try await session.respond(
                to: """
                QR/barcode payload (may be empty):
                \(qr.isEmpty ? "(none)" : qr)

                Ticket / booking text:
                \(clipped)
                """,
                generating: PassDraft.self
            )
            let draft = response.content
            let templateId = normalizeTemplate(draft.templateId)
            guard !templateId.isEmpty else { return nil }

            var fields: [String: String] = [:]
            func put(_ key: String, _ value: String?) {
                let v = (value ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                if !v.isEmpty { fields[key] = v }
            }
            put("qr_data", draft.qrData?.isEmpty == false ? draft.qrData : (qr.isEmpty ? nil : qr))
            put("name", draft.name)
            put("membership", draft.membership)
            put("origin", draft.origin)
            put("destination", draft.destination)
            put("passenger", draft.passenger)
            put("event", draft.event)
            put("seat", draft.seat)
            put("venue", draft.venue)
            put("booking_id", draft.bookingId)
            put("pnr", draft.pnr)
            put("train", draft.train)
            put("coach", draft.coach)
            put("flight", draft.flight)
            put("gate", draft.gate)
            put("restaurant", draft.restaurant)
            put("time", draft.time)
            put("party_size", draft.partySize)
            put("property", draft.property)
            put("check_in", draft.checkIn)
            put("check_out", draft.checkOut)
            put("guest", draft.guest)
            put("vehicle", draft.vehicle)
            put("pickup", draft.pickup)
            put("bus", draft.bus)

            if fields["qr_data"] == nil, let pnr = fields["pnr"] {
                fields["qr_data"] = pnr
            }

            let confidence = min(max(draft.confidence, 0.35), 0.95)
            return ClassificationResult(
                templateId: templateId,
                displayName: draft.displayName.isEmpty ? templateId : draft.displayName,
                confidence: confidence,
                fields: fields,
                stationIds: draft.stationIds,
                relevantDateISO8601: draft.relevantDateISO8601,
                rationale: draft.rationale.isEmpty ? "Filled by on-device Apple Intelligence" : draft.rationale,
                needsManualBrandPick: confidence < 0.55 || templateId.isEmpty,
                extracted: ticket,
                createdAt: Date()
            )
        } catch {
            return nil
        }
    }

    private static func normalizeTemplate(_ raw: String) -> String {
        let t = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let allowed = [
            "irctc", "bookmyshow", "indigo", "easydiner", "zomato-dineout",
            "swiggy-dineout", "airbnb", "namma-metro", "upi", "redbus", "zoomcar"
        ]
        if allowed.contains(t) { return t }
        if t.contains("metro") { return "namma-metro" }
        if t.contains("indigo") || t.contains("6e") { return "indigo" }
        if t.contains("irctc") || t.contains("rail") { return "irctc" }
        if t.contains("eazy") || t.contains("easy diner") { return "easydiner" }
        if t.contains("zomato") { return "zomato-dineout" }
        if t.contains("swiggy") { return "swiggy-dineout" }
        if t.contains("airbnb") { return "airbnb" }
        if t.contains("redbus") || t.contains("red bus") { return "redbus" }
        if t.contains("zoom") { return "zoomcar" }
        if t.contains("book") || t.contains("cinema") { return "bookmyshow" }
        if t.contains("upi") { return "upi" }
        return ""
    }
}

@available(iOS 26.0, *)
@Generable(description: "Structured Wallet pass fields extracted from a ticket or booking")
struct PassDraft {
    @Guide(description: "One of: irctc, bookmyshow, indigo, easydiner, zomato-dineout, swiggy-dineout, airbnb, namma-metro, upi, redbus, zoomcar")
    var templateId: String

    @Guide(description: "Human-readable brand or pass title")
    var displayName: String

    @Guide(description: "Confidence from 0 to 1")
    var confidence: Double

    @Guide(description: "Short reason for the template choice")
    var rationale: String

    var qrData: String?
    var name: String?
    var membership: String?
    var origin: String?
    var destination: String?
    var passenger: String?
    var event: String?
    var seat: String?
    var venue: String?
    var bookingId: String?
    var pnr: String?
    var train: String?
    var coach: String?
    var flight: String?
    var gate: String?
    var restaurant: String?
    var time: String?
    var partySize: String?
    var property: String?
    var checkIn: String?
    var checkOut: String?
    var guest: String?
    var vehicle: String?
    var pickup: String?
    var bus: String?

    @Guide(description: "Optional metro station codes")
    var stationIds: [String]

    var relevantDateISO8601: String?
}
#endif
