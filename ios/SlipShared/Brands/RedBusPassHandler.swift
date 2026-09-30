import Foundation

struct RedBusPassHandler: BrandPassHandler {
    let templateId = "redbus"
    let priority = 60
    func matches(qr: String, hay: String, ticket: ExtractedTicket) -> Bool { true }
    func classify(qr: String, hay: String, ticket: ExtractedTicket) -> ClassificationResult? {
        RedBusPassLogic.classify(qr: qr, hay: hay, ticket: ticket)
    }
}

enum RedBusPassLogic {
    static func classify(qr: String, hay: String, ticket: ExtractedTicket) -> ClassificationResult? {
        let h = hay.lowercased()
        guard h.contains("redbus") || h.contains("red bus") else { return nil }
        var fields: [String: String] = [:]
        if !qr.isEmpty { fields["qr_data"] = qr }
        if let origin = TicketText.firstMatch(in: ticket.recognizedText, pattern: #"(?i)(?:from|boarding)\s*[:\-]?\s*([A-Za-z .]{3,})"#) {
            fields["origin"] = origin
        }
        if let dest = TicketText.firstMatch(in: ticket.recognizedText, pattern: #"(?i)(?:to|dropping)\s*[:\-]?\s*([A-Za-z .]{3,})"#) {
            fields["destination"] = dest
        }
        if let seat = TicketText.firstMatch(in: ticket.recognizedText, pattern: #"(?i)seat\s*[:\-]?\s*([A-Z0-9,\- ]{1,12})"#) {
            fields["seat"] = seat
        }
        if let pnr = TicketText.firstMatch(in: ticket.recognizedText, pattern: #"(?i)(?:pnr|ticket\s*(?:no|number)|booking\s*id)\s*[:\-]?\s*([A-Z0-9]{6,})"#) {
            fields["pnr"] = pnr
            if fields["qr_data"] == nil { fields["qr_data"] = pnr }
        }
        if let passenger = TicketText.firstMatch(in: ticket.recognizedText, pattern: #"(?i)(?:passenger|traveller)\s*[:\-]?\s*([A-Za-z .]{3,})"#) {
            fields["passenger"] = passenger
        }
        guard fields["qr_data"] != nil || (fields["origin"] != nil && fields["destination"] != nil) else { return nil }
        return TicketText.result(templateId: "redbus", displayName: "redBus", confidence: 0.82,
                      fields: fields, stationIds: [], relevantDateISO8601: nil,
                      rationale: "Matched redBus ticket.", ticket: ticket)
    }


}
