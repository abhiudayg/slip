import Foundation

#if canImport(FoundationModels)
import FoundationModels
#endif

/// On-device Apple Intelligence fill with regex BrandClassifier fallback.
enum IntelligentBrandClassifier {
    /// Fast rules-only brand guess for the pre-extraction confirmation step.
    static func suggestBrand(_ ticket: ExtractedTicket) -> ClassificationResult {
        BrandClassifier.classify(ticket)
    }

    static func classify(_ ticket: ExtractedTicket, forcedTemplateId: String? = nil) async -> ClassificationResult {
        let rules: ClassificationResult
        if let forced = forcedTemplateId?.trimmingCharacters(in: .whitespacesAndNewlines), !forced.isEmpty {
            rules = BrandPassRegistry.extract(for: forced, ticket: ticket)
        } else {
            rules = BrandClassifier.classify(ticket)
        }
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            if let filled = await FoundationPassFiller.fill(from: ticket) {
                var merged = merge(ai: filled, rules: rules)
                if let forced = forcedTemplateId?.trimmingCharacters(in: .whitespacesAndNewlines), !forced.isEmpty {
                    merged.templateId = forced
                    merged.needsManualBrandPick = false
                    merged.confidence = max(merged.confidence, 0.92)
                    merged = enrich(merged)
                }
                return merged
            }
        }
        #endif
        return enrich(rules)
    }

    /// Prefer non-empty AI fields; backfill gaps from deterministic rules.
    static func merge(ai: ClassificationResult, rules: ClassificationResult) -> ClassificationResult {
        let handler = BrandPassRegistry.handler(for: rules.templateId)
        var preferRules = handler?.prefersRules(over: ai, rules: rules) == true
        let theatreIds: Set<String> = ["bookmyshow", "district"]
        let diningIds: Set<String> = ["easydiner", "zomato-dineout", "swiggy-dineout"]
        // Safety net: AI sometimes labels dining as theatre even when rules already matched dining.
        if !preferRules, diningIds.contains(rules.templateId), theatreIds.contains(ai.templateId), rules.confidence >= 0.7 {
            preferRules = true
        }

        let templateId: String
        if preferRules {
            templateId = rules.templateId
        } else if !ai.templateId.isEmpty {
            templateId = ai.templateId
        } else {
            templateId = rules.templateId
        }

        var fields = rules.fields
        let blocked = preferRules
            ? ["event", "venue", "seat", "origin", "destination", "pnr", "train"]
            : []
        for (key, value) in ai.fields {
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty { continue }
            if blocked.contains(key) { continue }
            let existing = fields[key]?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if existing.isEmpty || !preferRules {
                fields[key] = trimmed
            }
        }
        if preferRules, rules.templateId == "easydiner" || rules.templateId.contains("dineout") {
            let restaurant = fields["restaurant"]?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if restaurant.isEmpty,
               let event = ai.fields["event"]?.trimmingCharacters(in: .whitespacesAndNewlines),
               !event.isEmpty, !event.lowercased().hasPrefix("dee ") {
                fields["restaurant"] = event
            }
        }
        if fields["qr_data"]?.isEmpty != false,
           let qr = ai.extracted.qrPayload?.trimmingCharacters(in: .whitespacesAndNewlines),
           !qr.isEmpty {
            fields["qr_data"] = qr
        }

        let fallbackTitle = fields["vehicle"] ?? fields["restaurant"] ?? fields["event"] ?? rules.templateId
        let displayName: String
        if preferRules {
            displayName = rules.displayName.isEmpty ? fallbackTitle : rules.displayName
        } else if ai.displayName.isEmpty || ai.displayName == templateId {
            displayName = rules.displayName.isEmpty ? templateId : rules.displayName
        } else {
            displayName = ai.displayName
        }

        var result = ClassificationResult(
            templateId: templateId,
            displayName: displayName,
            confidence: max(ai.confidence, rules.confidence),
            fields: fields,
            stationIds: preferRules && rules.templateId == "zoomcar"
                ? []
                : (ai.stationIds.isEmpty ? rules.stationIds : ai.stationIds),
            relevantDateISO8601: preferRules
                ? (rules.relevantDateISO8601 ?? ai.relevantDateISO8601)
                : (ai.relevantDateISO8601 ?? rules.relevantDateISO8601),
            rationale: preferRules
                ? rules.rationale
                : (ai.rationale.isEmpty ? rules.rationale : ai.rationale),
            needsManualBrandPick: templateId.isEmpty,
            extracted: ai.extracted,
            createdAt: Date()
        )
        return enrich(result)
    }

    /// Fill template-required keys, brand-specific backfills, then prune foreign keys.
    static func enrich(_ classification: ClassificationResult) -> ClassificationResult {
        BrandPassRegistry.enrich(classification)
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
            Choose templateId from: irctc, bookmyshow, indigo, district, easydiner, zomato-dineout, swiggy-dineout, airbnb, namma-metro, upi, redbus, zoomcar.
            Dining rules: EazyDiner shows Booking Completed + Guests + Booking ID. Swiggy Dineout shows "Your table is booked", Confirmed, Dinner/Lunch time, "for N guests", restaurant + locality, Pay bill now / DineCash — use templateId swiggy-dineout and put the restaurant into restaurant (NOT event). Never classify restaurant reservations as bookmyshow/theatre. Never put "Confirmed"/"irmed" into bookingId. Zoomcar self-drive bookings show Booking Details, Host Details, Check In, car model + KA plate, trip start/end — use templateId zoomcar with vehicle/pickup/drop_off/guest/bookingId. Never classify Zoomcar as irctc/train.
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
            "irctc", "bookmyshow", "indigo", "district", "easydiner", "zomato-dineout",
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
        if t.contains("district") || t.contains("sunburn") || t.contains("boiler room") { return "district" }
        if t.contains("book") || t.contains("cinema") { return "bookmyshow" }
        if t.contains("upi") { return "upi" }
        return ""
    }
}

@available(iOS 26.0, *)
@Generable(description: "Structured Wallet pass fields extracted from a ticket or booking")
struct PassDraft {
    @Guide(description: "One of: irctc, bookmyshow, indigo, district, easydiner, zomato-dineout, swiggy-dineout, airbnb, namma-metro, upi, redbus, zoomcar")
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
    @Guide(description: "Movie or event title for BookMyShow, e.g. VIBE (A)")
    var event: String?
    @Guide(description: "Seat list only, e.g. A5, B6 or PC-F6, F7 — never put SCREEN 2 alone; screen may prefix as Screen 2 · A5, B6")
    var seat: String?
    @Guide(description: "Cinema venue, e.g. INOX: Nexus, Whitefield")
    var venue: String?
    @Guide(description: "Booking ID only, e.g. TPAGJBY — not the full QR payload")
    var bookingId: String?
    var pnr: String?
    var train: String?
    var coach: String?
    var flight: String?
    var gate: String?
    @Guide(description: "Restaurant name for EazyDiner/Zomato/Swiggy dining, e.g. Underdoggs Whitefield — never put this in event")
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


