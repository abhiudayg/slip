import Foundation

/// Generic airline/OTA boarding fallback → indigo layout.
struct AirlineHintPassHandler: BrandPassHandler {
    let templateId = "indigo"
    let priority = 55
    func matches(qr: String, hay: String, ticket: ExtractedTicket) -> Bool { true }
    func classify(qr: String, hay: String, ticket: ExtractedTicket) -> ClassificationResult? {
        AirlineHintPassLogic.classify(qr: qr, hay: hay, ticket: ticket)
    }
}

enum AirlineHintPassLogic {
    static func classify(qr: String, hay: String, ticket: ExtractedTicket) -> ClassificationResult? {
        let hit = hay.contains("makemytrip")
            || hay.contains("mmt")
            || hay.contains("cleartrip")
            || hay.contains("boarding pass")
            || hay.contains("airline")
            || (hay.contains("pnr") && hay.contains("flight"))
        guard hit else { return nil }

        let body = ticket.recognizedText
        var fields: [String: String] = [
            "qr_data": qr,
            "origin": "",
            "destination": "",
            "passenger": "",
            "flight": "",
            "seat": "",
            "pnr": "",
            "gate": ""
        ]
        if let pnr = TicketText.firstMatch(in: body, pattern: #"(?i)(?:pnr|booking\s*ref(?:erence)?)\s*[:\-]?\s*([A-Z0-9]{6})"#) {
            fields["pnr"] = pnr.uppercased()
            if qr.isEmpty { fields["qr_data"] = pnr.uppercased() }
        }
        if let flight = TicketText.firstMatch(in: body, pattern: #"\b([A-Z]{2}\s?\d{2,4})\b"#) {
            fields["flight"] = flight.uppercased()
        }
        if let seat = TicketText.firstMatch(in: body, pattern: #"(?i)seat\s*[:\-]?\s*([0-9]{1,2}[A-F])"#) {
            fields["seat"] = seat.uppercased()
        }
        let codes = TicketText.matches(in: body, pattern: #"\b([A-Z]{3})\b"#)
            .filter { !["THE","AND","FOR","PDF","PNR","SEQ","STD","ETA","GST"].contains($0) }
        if codes.count >= 2 {
            fields["origin"] = codes[0]
            fields["destination"] = codes[1]
        }

        return TicketText.result(
            templateId: "indigo",
            displayName: "Flight boarding",
            confidence: 0.58,
            fields: fields,
            rationale: "Detected generic airline/OTA boarding cues — using IndiGo boarding layout",
            ticket: ticket
        )
    }


}
