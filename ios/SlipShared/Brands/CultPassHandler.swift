import Foundation

struct CultPassHandler: BrandPassHandler {
    let templateId = "cult"
    let priority = 110
    func matches(qr: String, hay: String, ticket: ExtractedTicket) -> Bool { true }
    func classify(qr: String, hay: String, ticket: ExtractedTicket) -> ClassificationResult? {
        CultPassLogic.classify(qr: qr, hay: hay, ticket: ticket)
    }
}

enum CultPassLogic {
    static func classify(qr: String, hay: String, ticket: ExtractedTicket) -> ClassificationResult? {
        let hit = hay.contains("cult.fit")
            || hay.contains("cultfit")
            || hay.contains("cure.fit")
            || (hay.contains("cult") && (hay.contains("member") || hay.contains("check-in") || hay.contains("check in")))
        guard hit || (hay.contains("member") && hay.contains("fitness") && !qr.isEmpty) else { return nil }

        var fields: [String: String] = [
            "qr_data": qr,
            "name": "",
            "membership": "Member"
        ]
        if let name = TicketText.firstMatch(in: ticket.recognizedText, pattern: #"(?i)(?:member|name)\s*[:\-]?\s*([A-Za-z][A-Za-z .]{2,})"#) {
            fields["name"] = name
        }
        if let plan = TicketText.firstMatch(in: ticket.recognizedText, pattern: #"(?i)(elite|pro|play|pass|unlimited)"#) {
            fields["membership"] = plan.capitalized
        }

        return TicketText.result(
            templateId: "cult",
            displayName: "Cult.fit",
            confidence: hay.contains("cult") ? 0.92 : 0.7,
            fields: fields,
            rationale: "Detected Cult.fit membership cues",
            ticket: ticket
        )
    }


}
