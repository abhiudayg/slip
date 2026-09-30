import Foundation

struct IndigoPassHandler: BrandPassHandler {
    let templateId = "indigo"
    let priority = 50
    func matches(qr: String, hay: String, ticket: ExtractedTicket) -> Bool { true }
    func classify(qr: String, hay: String, ticket: ExtractedTicket) -> ClassificationResult? {
        IndigoPassLogic.classify(qr: qr, hay: hay, ticket: ticket)
    }
}

enum IndigoPassLogic {
    static func classify(qr: String, hay: String, ticket: ExtractedTicket) -> ClassificationResult? {
        let hit = hay.contains("indigo")
            || hay.contains("6e-")
            || hay.contains("goindigo")
            || (hay.contains("boarding pass") && (hay.contains("6e") || hay.contains("flight")))
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
        if let flight = TicketText.firstMatch(in: body, pattern: #"(?i)\b(6E[-\s]?\d{2,4})\b"#) {
            fields["flight"] = flight.uppercased().replacingOccurrences(of: " ", with: "")
        }
        if let pnr = TicketText.firstMatch(in: body, pattern: #"(?i)(?:pnr|booking\s*ref(?:erence)?)\s*[:\-]?\s*([A-Z0-9]{6})"#) {
            fields["pnr"] = pnr.uppercased()
            if fields["qr_data"]?.isEmpty == true { fields["qr_data"] = pnr.uppercased() }
        }
        if let seat = TicketText.firstMatch(in: body, pattern: #"(?i)seat\s*[:\-]?\s*([0-9]{1,2}[A-F])"#) {
            fields["seat"] = seat.uppercased()
        }
        if let gate = TicketText.firstMatch(in: body, pattern: #"(?i)gate\s*[:\-]?\s*([A-Z0-9]{1,3})"#) {
            fields["gate"] = gate.uppercased()
        }
        if let passenger = TicketText.firstMatch(in: body, pattern: #"(?i)(?:passenger|name)\s*[:\-]?\s*([A-Za-z .]{3,40})"#) {
            fields["passenger"] = passenger.trimmingCharacters(in: .whitespaces)
        }
        let codes = TicketText.matches(in: body, pattern: #"\b([A-Z]{3})\b"#)
            .filter { !["THE","AND","FOR","PDF","PNR","SEQ","STD","ETA","GATE","IND","GST"].contains($0) }
        if codes.count >= 2 {
            fields["origin"] = codes[0]
            fields["destination"] = codes[1]
        }
        if fields["qr_data"]?.isEmpty == true, let pnr = fields["pnr"], !pnr.isEmpty {
            fields["qr_data"] = pnr
        }

        let conf = (fields["pnr"]?.isEmpty == false || !qr.isEmpty) ? 0.86 : 0.62
        return TicketText.result(
            templateId: "indigo",
            displayName: "IndiGo",
            confidence: conf,
            fields: fields,
            rationale: "Detected IndiGo / flight boarding cues",
            ticket: ticket
        )
    }

    /// Generic airline/OTA boarding when brand-specific rules miss.

}
