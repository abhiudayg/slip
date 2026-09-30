import Foundation

struct ZoomcarPassHandler: BrandPassHandler {
    let templateId = "zoomcar"
    let priority = 20
    func matches(qr: String, hay: String, ticket: ExtractedTicket) -> Bool { true }
    func classify(qr: String, hay: String, ticket: ExtractedTicket) -> ClassificationResult? {
        ZoomcarPassLogic.classify(qr: qr, hay: hay, ticket: ticket)
    }
    func enrich(_ result: ClassificationResult) -> ClassificationResult {
        var result = result
        let qr = result.fields["qr_data"] ?? result.extracted.qrPayload ?? ""
        let parsed = ZoomcarPassLogic.extractFields(from: result.extracted.recognizedText, qr: qr)
        for (key, value) in parsed {
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            let existing = result.fields[key]?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if existing.isEmpty, !trimmed.isEmpty {
                result.fields[key] = trimmed
            }
        }
        let booking = result.fields["booking_id"]?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let q = result.fields["qr_data"]?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if q.isEmpty, !booking.isEmpty {
            result.fields["qr_data"] = booking
        }
        if result.displayName.lowercased() == "zoomcar" || result.displayName.isEmpty,
           let vehicle = result.fields["vehicle"], !vehicle.isEmpty {
            result.displayName = vehicle
        }
        return result
    }
    func prefersRules(over ai: ClassificationResult, rules: ClassificationResult) -> Bool {
        let transitIds: Set<String> = ["irctc", "indigo", "namma-metro", "redbus"]
        let theatreIds: Set<String> = ["bookmyshow", "district"]
        return rules.templateId == "zoomcar"
            && rules.confidence >= 0.7
            && (transitIds.contains(ai.templateId) || theatreIds.contains(ai.templateId)
                || ai.templateId.isEmpty || ai.templateId == "zoomcar")
    }
}

enum ZoomcarPassLogic {
    static func classify(qr: String, hay: String, ticket: ExtractedTicket) -> ClassificationResult? {
        let h = hay.lowercased()
        let branded = h.contains("zoomcar") || h.contains("zoom car")
        // Booking Details UI often omits the Zoomcar word in OCR.
        let layout = (h.contains("host details") || h.contains("check-in instructions")
                || h.contains("check in instructions") || h.contains("rules & tips for your ride")
                || h.contains("opens 30 mins before") || (h.contains("check in") && h.contains("trip start")))
            && (h.contains("booking details") || h.contains("location") || h.contains("get directions"))
        let plateHit = TicketText.firstMatch(in: ticket.recognizedText, pattern: #"\b([A-Z]{2}\d{1,2}[A-Z]{1,3}\d{3,4})\b"#) != nil
        let carHit = TicketText.firstMatch(
            in: ticket.recognizedText,
            pattern: #"(?i)\b((?:Hyundai|Maruti|Tata|Toyota|Honda|Mahindra|Kia|MG|Renault|Skoda|Volkswagen|Ford)[^\n]{0,48})"#
        ) != nil
        guard branded || layout || (plateHit && carHit && h.contains("booking")) else { return nil }

        var fields = extractFields(from: ticket.recognizedText, qr: qr)
        guard fields["vehicle"] != nil || fields["booking_id"] != nil || fields["qr_data"] != nil else {
            return nil
        }

        let title = fields["vehicle"]?.trimmingCharacters(in: .whitespacesAndNewlines)
        let shown = (title?.isEmpty == false) ? title! : "Zoomcar"
        let conf: Double = branded ? 0.94 : (layout ? 0.9 : 0.82)
        return TicketText.result(
            templateId: "zoomcar",
            displayName: shown,
            confidence: conf,
            fields: fields,
            stationIds: [],
            relevantDateISO8601: zoomcarRelevantDate(from: ticket.recognizedText),
            rationale: "Matched Zoomcar self-drive booking (not a train ticket).",
            ticket: ticket
        )
    }

    /// Shared Zoomcar field parser — also used to backfill Apple Intelligence drafts.
    static func extractFields(from text: String, qr: String) -> [String: String] {
        var fields: [String: String] = [:]
        if !qr.isEmpty { fields["qr_data"] = qr }

        if let booking = TicketText.firstMatch(in: text, pattern: #"(?i)booking\s*(?:id|no\.?|#)?\s*[:\-]?\s*([A-Z0-9]{6,14})"#)
            ?? TicketText.firstMatch(in: text, pattern: #"(?i)booking details\s*\n\s*([A-Z0-9]{6,14})"#) {
            let junk: Set<String> = ["DETAILS", "CHECKIN", "HOSTDET", "LOCATION"]
            if !junk.contains(booking.uppercased()) {
                fields["booking_id"] = booking.uppercased()
                if fields["qr_data"] == nil { fields["qr_data"] = booking.uppercased() }
            }
        }

        if let plate = TicketText.firstMatch(in: text, pattern: #"\b([A-Z]{2}\d{1,2}[A-Z]{1,3}\d{3,4})\b"#) {
            fields["booking_id"] = fields["booking_id"] ?? plate
            if fields["qr_data"] == nil { fields["qr_data"] = plate }
        }

        if let vehicle = TicketText.firstMatch(
            in: text,
            pattern: #"(?i)\b((?:Hyundai|Maruti|Tata|Toyota|Honda|Mahindra|Kia|MG|Renault|Skoda|Volkswagen|Ford)[^\n]{0,48})"#
        ) ?? TicketText.firstMatch(in: text, pattern: #"(?i)(?:car|vehicle|model)\s*[:\-]?\s*([^\n]{3,60})"#) {
            var v = vehicle.trimmingCharacters(in: .whitespacesAndNewlines)
            if let plate = TicketText.firstMatch(in: text, pattern: #"\b([A-Z]{2}\d{1,2}[A-Z]{1,3}\d{3,4})\b"#),
               !v.uppercased().contains(plate) {
                v = "\(v) · \(plate)"
            }
            fields["vehicle"] = v
        }

        // Location section address (pickup). Prefer line after "Location".
        if let pickup = TicketText.firstMatch(in: text, pattern: #"(?i)location\s*\n\s*([^\n]{8,90})"#)
            ?? TicketText.firstMatch(in: text, pattern: #"(?i)(?:pickup|pick[\s\-]?up|unlock)\s*[:\-]?\s*([^\n]{5,90})"#) {
            let p = pickup.trimmingCharacters(in: .whitespacesAndNewlines)
            if !p.lowercased().hasPrefix("get direction") {
                fields["pickup"] = p
            }
        }

        // Trip endpoints: "Fri, 02 Oct" … "08:00 AM" and "Sun, 04 Oct" … "11:00 PM"
        let tripEnds = TicketText.matches(
            in: text,
            pattern: #"(?i)((?:Mon|Tue|Wed|Thu|Fri|Sat|Sun)[a-z]*,?\s+\d{1,2}\s+(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\s+(?:[01]?\d|2[0-3])[:.][0-5]\d\s*(?:AM|PM))"#
        )
        if tripEnds.count >= 2 {
            fields["drop_off"] = tripEnds[tripEnds.count - 1]
        } else if tripEnds.count == 1 {
            fields["drop_off"] = tripEnds[0]
        }

        // Guest / renter name — often appears above the vehicle line.
        if let guest = TicketText.firstMatch(in: text, pattern: #"(?i)(?:driver|guest|renter|booked by)\s*[:\-]?\s*([A-Za-z][A-Za-z .]{2,40})"#) {
            fields["guest"] = guest.trimmingCharacters(in: .whitespaces)
        } else if let guest = zoomcarGuestName(from: text) {
            fields["guest"] = guest
        }

        return fields
    }

    static func zoomcarGuestName(from text: String) -> String? {
        let lines = text.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        for (idx, line) in lines.enumerated() {
            // Name line immediately above a car model line.
            if idx + 1 < lines.count,
               lines[idx + 1].range(
                of: #"(?i)\b(?:Hyundai|Maruti|Tata|Toyota|Honda|Mahindra|Kia|MG)\b"#,
                options: .regularExpression
               ) != nil {
                if line.range(of: #"^[A-Za-z][A-Za-z .]{2,40}$"#, options: .regularExpression) != nil {
                    let lower = line.lowercased()
                    if ["location", "host details", "booking details", "check in", "confirmed"].contains(lower) {
                        continue
                    }
                    return line
                }
            }
        }
        return nil
    }

    static func zoomcarRelevantDate(from text: String) -> String? {
        let starts = TicketText.matches(
            in: text,
            pattern: #"(?i)((?:Mon|Tue|Wed|Thu|Fri|Sat|Sun)[a-z]*,?\s+\d{1,2}\s+(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\s+(?:[01]?\d|2[0-3])[:.][0-5]\d\s*(?:AM|PM))"#
        )
        guard let first = starts.first,
              let clock = TicketText.firstMatch(in: first, pattern: #"((?:[01]?\d|2[0-3])[:.][0-5]\d\s*(?:AM|PM))$"#) else {
            return nil
        }
        let datePart = first.replacingOccurrences(of: clock, with: "").trimmingCharacters(in: .whitespaces)
        if let d = TicketText.parseFlexibleDateTime(datePart, clock) {
            return ISO8601DateFormatter().string(from: d)
        }
        return nil
    }



}
