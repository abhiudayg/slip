import Foundation

struct DistrictPassHandler: BrandPassHandler {
    let templateId = "district"
    let priority = 80
    func matches(qr: String, hay: String, ticket: ExtractedTicket) -> Bool { true }
    func classify(qr: String, hay: String, ticket: ExtractedTicket) -> ClassificationResult? {
        DistrictPassLogic.classify(qr: qr, hay: hay, ticket: ticket)
    }
    func enrich(_ result: ClassificationResult) -> ClassificationResult {
        // Movies share BMS field shape.
        BookMyShowPassHandler().enrich(result)
    }
    func prefersRules(over ai: ClassificationResult, rules: ClassificationResult) -> Bool {
        rules.confidence >= 0.7 && (ai.templateId == "bookmyshow" || ai.templateId.isEmpty || ai.templateId == "district")
    }
}

enum DistrictPassLogic {
    static func classify(qr: String, hay: String, ticket: ExtractedTicket) -> ClassificationResult? {
        let h = hay.lowercased()
        let festivalHit = h.contains("district")
            || h.contains("sunburn")
            || h.contains("boiler room")
            || (h.contains("wristband") && (h.contains("festival") || h.contains("vip") || h.contains("pit")))
            || (h.contains("nfc") && h.contains("festival"))
        let movieHit = (
                h.contains("district")
                || (h.contains("booking confirmed") && h.contains("booking code") && h.contains("booking id"))
                || (h.contains("booking code") && h.contains("screen") && h.contains("tickets"))
            )
            && (h.contains("screen") || h.contains("tickets"))
            && (h.contains("inox") || h.contains("pvr") || h.contains("cinepolis") || h.contains("3d") || h.contains("2d")
                || BookMyShowPassLogic.cinemaSeatList(from: ticket.recognizedText) != nil)
        guard festivalHit || movieHit else { return nil }

        // Movie tickets on District share BMS-shaped fields (event/seat/venue/time).
        if movieHit && (h.contains("screen") || h.contains("inox") || h.contains("pvr") || h.contains("tickets")) {
            var fields = BookMyShowPassLogic.extractFields(from: ticket.recognizedText, qr: qr)
            let relevant = fields.removeValue(forKey: "_relevantDateISO8601")
            let eventTitle = fields["event"]?.trimmingCharacters(in: .whitespacesAndNewlines)
            let display = (eventTitle?.isEmpty == false) ? eventTitle! : "District"
            return TicketText.result(
                templateId: "district",
                displayName: display,
                confidence: 0.9,
                fields: fields,
                stationIds: [],
                relevantDateISO8601: relevant,
                rationale: "Matched District movie booking with seats (not screen-as-seat).",
                ticket: ticket
            )
        }

        var fields: [String: String] = [:]
        if !qr.isEmpty { fields["qr_data"] = qr }
        let text = ticket.recognizedText
        if let event = TicketText.firstMatch(in: text, pattern: #"(?i)(?:event|show|concert|festival)\s*[:\-]?\s*(.+)"#) {
            fields["event"] = event
        } else if h.contains("sunburn") {
            fields["event"] = "Sunburn Arena"
        } else {
            fields["event"] = "District Festival"
        }
        if let venue = TicketText.firstMatch(in: text, pattern: #"(?i)(?:venue|arena|centre|center)\s*[:\-]?\s*(.+)"#) {
            fields["venue"] = venue
        }
        if let tier = TicketText.firstMatch(in: text, pattern: #"(?i)(?:tier|access)\s*[:\-]?\s*(VIP[^\n]{0,24}|All[- ]Access[^\n]{0,16}|GA[^\n]{0,12})"#)
            ?? TicketText.firstMatch(in: text, pattern: #"(?i)\b(VIP\s+PIT\s+PASS|VIP\s+ALL[- ]ACCESS|ALL[- ]ACCESS)\b"#) {
            fields["tier"] = tier
        }
        if let gate = TicketText.firstMatch(in: text, pattern: #"(?i)(?:gate|entry)\s*[:\-#]?\s*([A-Z0-9][^\n]{0,24})"#) {
            fields["gate"] = gate
        }
        if let zone = TicketText.firstMatch(in: text, pattern: #"(?i)(?:zone)\s*[:\-]?\s*([^\n]{2,40})"#) {
            fields["zone"] = zone
        }
        if let passholder = TicketText.firstMatch(in: text, pattern: #"(?i)(?:passholder|guest|name)\s*[:\-]?\s*([A-Za-z .]{3,40})"#) {
            fields["passholder"] = passholder
        }
        if let booking = TicketText.firstMatch(in: text, pattern: #"(?i)(?:wristband|booking|pass)\s*(?:id|no\.?|#)?\s*[:\-]?\s*([A-Z0-9\-]{4,})"#) {
            fields["booking_id"] = booking
            if fields["qr_data"] == nil { fields["qr_data"] = booking }
        }
        if let time = TicketText.firstMatch(in: text, pattern: #"(?i)(?:gates?\s*open|date)\s*[:\-]?\s*([^\n]{4,40})"#) {
            fields["time"] = time
        }
        if fields["qr_data"] == nil, let booking = fields["booking_id"] {
            fields["qr_data"] = booking
        }
        guard fields["qr_data"] != nil || fields["event"] != nil else { return nil }
        return TicketText.result(
            templateId: "district",
            displayName: "District",
            confidence: 0.82,
            fields: fields,
            stationIds: [],
            relevantDateISO8601: nil,
            rationale: "Matched District festival / NFC wristband text.",
            ticket: ticket
        )
    }


}
