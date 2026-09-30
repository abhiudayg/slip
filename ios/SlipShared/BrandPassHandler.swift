import Foundation

/// Per-brand extraction + enrich contract.
/// Each brand owns its OCR quirks and AI/rules merge preference.
protocol BrandPassHandler {
    var templateId: String { get }
    /// Lower runs earlier in the classify chain.
    var priority: Int { get }
    func matches(qr: String, hay: String, ticket: ExtractedTicket) -> Bool
    func classify(qr: String, hay: String, ticket: ExtractedTicket) -> ClassificationResult?
    func enrich(_ result: ClassificationResult) -> ClassificationResult
    func prefersRules(over ai: ClassificationResult, rules: ClassificationResult) -> Bool
}

extension BrandPassHandler {
    func prefersRules(over ai: ClassificationResult, rules: ClassificationResult) -> Bool { false }
    func enrich(_ result: ClassificationResult) -> ClassificationResult { result }
}

enum BrandPassRegistry {
    static let handlers: [BrandPassHandler] = [
        UPIPassHandler(),          // 10
        ZoomcarPassHandler(),      // 20
        DiningPassHandler.easydiner, // 30
        DiningPassHandler.zomato,    // 31
        DiningPassHandler.swiggy,    // 32
        IRCTCPassHandler(),        // 40
        IndigoPassHandler(),       // 50
        AirlineHintPassHandler(),  // 55
        RedBusPassHandler(),       // 60
        NammaMetroPassHandler(),   // 70
        DistrictPassHandler(),     // 80
        BookMyShowPassHandler(),   // 90
        AirbnbPassHandler(),       // 100
        CultPassHandler()          // 110
    ].sorted { $0.priority < $1.priority }

    static func handler(for templateId: String) -> BrandPassHandler? {
        // Dining shares one type with three ids
        handlers.first { $0.templateId == templateId }
    }

    static func classify(_ ticket: ExtractedTicket) -> ClassificationResult {
        let hay = ticket.haystack
        let qr = ticket.qrPayload?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        for handler in handlers {
            if let result = handler.classify(qr: qr, hay: hay, ticket: ticket) {
                return result
            }
        }
        return TicketText.unknown(ticket: ticket, qr: qr)
    }

    /// Run brand-specific field extraction for a user-confirmed template.
    static func extract(for templateId: String, ticket: ExtractedTicket) -> ClassificationResult {
        let hay = ticket.haystack
        let qr = ticket.qrPayload?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if let handler = handler(for: templateId),
           let result = handler.classify(qr: qr, hay: hay, ticket: ticket) {
            var confirmed = result
            confirmed.templateId = templateId
            confirmed.needsManualBrandPick = false
            confirmed.confidence = max(confirmed.confidence, 0.92)
            if confirmed.rationale.isEmpty {
                confirmed.rationale = "Brand confirmed · fields extracted"
            }
            return enrich(confirmed)
        }

        var fields: [String: String] = [:]
        if !qr.isEmpty { fields["qr_data"] = qr }
        let shell = ClassificationResult(
            templateId: templateId,
            displayName: friendlyName(for: templateId),
            confidence: 0.85,
            fields: fields,
            stationIds: [],
            relevantDateISO8601: nil,
            rationale: "Brand selected · extracting fields",
            needsManualBrandPick: false,
            extracted: ticket,
            createdAt: Date()
        )
        return enrich(shell)
    }

    static func friendlyName(for templateId: String) -> String {
        switch templateId {
        case "zomato-dineout": return "Zomato Dineout"
        case "swiggy-dineout": return "Swiggy Dineout"
        case "easydiner": return "EazyDiner"
        case "bookmyshow": return "BookMyShow"
        case "namma-metro": return "Namma Metro"
        case "irctc": return "IRCTC"
        case "indigo": return "IndiGo"
        case "redbus": return "redBus"
        case "zoomcar": return "Zoomcar"
        case "upi": return "UPI"
        case "airbnb": return "Airbnb"
        case "district": return "District"
        default: return templateId.replacingOccurrences(of: "-", with: " ").capitalized
        }
    }

    static func enrich(_ classification: ClassificationResult) -> ClassificationResult {
        var result = classification
        let schema = BrandFields.schema(for: result.templateId)
        for key in schema.all where result.fields[key] == nil {
            result.fields[key] = ""
        }
        if let handler = handler(for: result.templateId) {
            result = handler.enrich(result)
        }
        result.fields = BrandFields.prune(result.fields, templateId: result.templateId)
        return result
    }
}
