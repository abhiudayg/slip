import Foundation

struct BookMyShowPassHandler: BrandPassHandler {
    let templateId = "bookmyshow"
    let priority = 90
    func matches(qr: String, hay: String, ticket: ExtractedTicket) -> Bool { true }
    func classify(qr: String, hay: String, ticket: ExtractedTicket) -> ClassificationResult? {
        BookMyShowPassLogic.classify(qr: qr, hay: hay, ticket: ticket)
    }
    func enrich(_ result: ClassificationResult) -> ClassificationResult {
        var result = result
        let qr = result.fields["qr_data"] ?? result.extracted.qrPayload ?? ""
        let parsed = BookMyShowPassLogic.extractFields(from: result.extracted.recognizedText, qr: qr)
        let seatExisting = result.fields["seat"]?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let seatIsScreenOnly = seatExisting.range(of: #"^screen\s*\d+$"#, options: [.regularExpression, .caseInsensitive]) != nil
        for (key, value) in parsed where key != "_relevantDateISO8601" {
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            let existing = result.fields[key]?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let shouldOverwriteSeat = key == "seat" && seatIsScreenOnly && !trimmed.isEmpty
            if (existing.isEmpty || shouldOverwriteSeat), !trimmed.isEmpty {
                result.fields[key] = trimmed
            }
        }
        if let relevant = parsed["_relevantDateISO8601"], result.relevantDateISO8601 == nil {
            result.relevantDateISO8601 = relevant
        }
        if let seats = BookMyShowPassLogic.cinemaSeatList(from: result.extracted.recognizedText) {
            let cur = result.fields["seat"]?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if cur.isEmpty || cur.range(of: #"^screen\s*\d+$"#, options: [.regularExpression, .caseInsensitive]) != nil {
                if let screen = TicketText.firstMatch(in: result.extracted.recognizedText, pattern: #"(?i)screen\s*([0-9]{1,2})"#) {
                    result.fields["seat"] = "Screen \(screen) · \(seats)"
                } else {
                    result.fields["seat"] = seats
                }
            }
        }
        let event = result.fields["event"]?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if event.isEmpty {
            let dn = result.displayName.trimmingCharacters(in: .whitespacesAndNewlines)
            if !dn.isEmpty, dn.lowercased() != "bookmyshow", dn.lowercased() != "unknown" {
                result.fields["event"] = dn
            }
        }
        if result.displayName.lowercased() == "bookmyshow",
           let event = result.fields["event"], !event.isEmpty {
            result.displayName = event
        }
        return result
    }
}

enum BookMyShowPassLogic {
    static func classify(qr: String, hay: String, ticket: ExtractedTicket) -> ClassificationResult? {
        // Restaurant reservation UIs must not become movie tickets.
        let diningLayout = (
                (hay.contains("booking completed") || hay.contains("book again") || hay.contains("restaurant offer"))
                && (hay.contains("guests") || hay.contains("guest"))
            )
            || (
                (hay.contains("booking confirmed") || hay.contains("reach restaurant") || hay.contains("pay bill"))
                && (hay.contains("guest") || hay.contains("guests"))
                && !hay.contains("screen")
                && !hay.contains("inox")
                && !hay.contains("pvr")
            )
        if diningLayout { return nil }

        // District by PhonePe movie confirmations (Booking Confirmed + SCREEN + Booking ID).
        let districtMovie = (hay.contains("booking confirmed") || hay.contains("booking code"))
            && (hay.contains("screen") || hay.contains("tickets"))
            && (hay.contains("inox") || hay.contains("pvr") || hay.contains("cinepolis") || hay.contains("cinema")
                || cinemaSeatList(from: ticket.recognizedText) != nil)

        let hit = hay.contains("bookmyshow")
            || hay.contains("book my show")
            || hay.contains("bms")
            || hay.contains("paytm insider")
            || hay.contains("m-ticket")
            || hay.contains("mticket")
            || hay.contains("inox")
            || hay.contains("pvr")
            || hay.contains("cinepolis")
            || hay.contains("carnival cinemas")
            || districtMovie
            || (hay.contains("ticket") && (hay.contains("screen") || hay.contains("2d") || hay.contains("3d") || hay.contains("imax")))
            || (hay.contains("seat") && (hay.contains("cinema") || hay.contains("theatre") || hay.contains("theater") || hay.contains("screen")))
        guard hit else { return nil }

        let body = ticket.recognizedText
        var fields = extractFields(from: body, qr: qr)

        var relevant = fields.removeValue(forKey: "_relevantDateISO8601")
        if relevant == nil,
           let dateStr = TicketText.firstMatch(in: body, pattern: #"(\d{1,2}[\/\-]\d{1,2}[\/\-]\d{2,4})"#),
           let date = TicketText.parseLooseDate(dateStr) {
            relevant = ISO8601DateFormatter().string(from: date.addingTimeInterval(-2 * 3600))
        }

        let eventTitle = fields["event"]?.trimmingCharacters(in: .whitespacesAndNewlines)
        let display = (eventTitle?.isEmpty == false) ? eventTitle! : "BookMyShow"
        let filled = ["event", "seat", "venue", "booking_id"].filter { !(fields[$0] ?? "").isEmpty }.count
        let conf: Double
        if hay.contains("bookmyshow") || hay.contains("book my show") || hay.contains("m-ticket") {
            conf = filled >= 3 ? 0.95 : 0.85
        } else {
            conf = filled >= 3 ? 0.88 : 0.72
        }

        return TicketText.result(
            templateId: "bookmyshow",
            displayName: display,
            confidence: conf,
            fields: fields,
            relevantDateISO8601: relevant,
            rationale: "Extracted from movie booking text with clear title and venue details.",
            ticket: ticket
        )
    }

    /// Shared BMS field parser — also used to backfill Apple Intelligence drafts.
    static func extractFields(from body: String, qr: String) -> [String: String] {
        var fields: [String: String] = [
            "qr_data": qr,
            "event": "",
            "seat": "",
            "venue": "",
            "booking_id": "",
            "time": ""
        ]

        // QR payloads are often "BOOKINGID, numeric, dd-MMM-yyyy, HH:mm"
        let qrParts = qr.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        if qrParts.count >= 1, qrParts[0].range(of: #"^[A-Z0-9]{5,12}$"#, options: .regularExpression) != nil {
            fields["booking_id"] = qrParts[0].uppercased()
        }
        if qrParts.count >= 4 {
            let datePart = qrParts[2]
            let timePart = qrParts[3]
            if fields["time"]?.isEmpty != false {
                fields["time"] = "\(datePart) · \(timePart)"
            }
            if let date = TicketText.parseLooseDate(datePart) ?? TicketText.parseShowDateTime(datePart, timePart) {
                fields["_relevantDateISO8601"] = ISO8601DateFormatter().string(from: date.addingTimeInterval(-2 * 3600))
            }
        }

        if let booking = TicketText.firstMatch(in: body, pattern: #"(?i)booking\s*id\s*[:\-]?\s*([A-Z0-9]{5,12})"#)
            ?? TicketText.firstMatch(in: body, pattern: #"(?i)booking\s*code\s*[:\-]?\s*([A-Z0-9]{6,})"#)
            ?? TicketText.firstMatch(in: body, pattern: #"(?i)(?:booking|bms)\s*(?:id|#)?\s*[:\-]?\s*([A-Z0-9]{6,})"#) {
            fields["booking_id"] = booking.uppercased()
        }

        if let venue = TicketText.firstMatch(in: body, pattern: #"(?i)((?:INOX|PVR|Cinepolis|Carnival|Miraj|MovieTime|SPI)[^.\n]{0,60})"#)
            ?? TicketText.firstMatch(in: body, pattern: #"(?i)(?:venue|cinema|theatre|theater)\s*[:\-]?\s*([^\n]{4,60})"#) {
            fields["venue"] = venue.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        // Screen is NOT a seat. District/BMS often show "QR - A5, B6" beside "SCREEN 2".
        let screenNo = TicketText.firstMatch(in: body, pattern: #"(?i)screen\s*([0-9]{1,2})"#)
        if let seats = cinemaSeatList(from: body) {
            var cleaned = seats
            if let screenNo {
                cleaned = "Screen \(screenNo) · \(cleaned)"
            }
            fields["seat"] = cleaned
        }
        // Do not fall back to "Screen N" alone — that overwrites real seats with auditorium label.

        // Prefer show date+time ("25 Dec, 06:20 PM") over status-bar clocks ("18:19").
        if let show = TicketText.firstMatch(
            in: body,
            pattern: #"(?i)(\d{1,2}\s+(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\.?\s*,?\s*\d{1,2}:\d{2}\s*(?:AM|PM)(?:\s*[-–]\s*\d{1,2}:\d{2}\s*(?:AM|PM))?)"#
        ) ?? TicketText.firstMatch(
            in: body,
            pattern: #"(?i)((?:Mon|Tue|Wed|Thu|Fri|Sat|Sun)[a-z]*\.?,?\s*\d{1,2}\s*[A-Za-z]{3,9}[^.\n]{0,40}\d{1,2}:\d{2}\s*(?:AM|PM)?)"#
        ) ?? TicketText.firstMatch(
            in: body,
            pattern: #"(\d{1,2}:\d{2}\s*(?:AM|PM))"#
        ) {
            var cleaned = show.replacingOccurrences(of: #"\s*\|\s*"#, with: " · ", options: .regularExpression)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            // Keep start time when range present: "25 Dec, 06:20 PM - 09:57 PM"
            if let start = TicketText.firstMatch(in: cleaned, pattern: #"(?i)(\d{1,2}\s+(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\.?\s*,?\s*\d{1,2}:\d{2}\s*(?:AM|PM))"#)
                ?? TicketText.firstMatch(in: cleaned, pattern: #"(\d{1,2}:\d{2}\s*(?:AM|PM))"#) {
                cleaned = start
            }
            fields["time"] = cleaned
            if fields["_relevantDateISO8601"] == nil,
               let iso = cinemaRelevantDate(from: cleaned) {
                fields["_relevantDateISO8601"] = iso
            }
        }

        // Event / movie title: prefer "TITLE (A)" / "TITLE (UA)" lines; skip UI chrome
        let skipEvent = ["ticket", "share", "rate", "reward", "amount", "cancel", "booking", "screen", "inox", "pvr", "hindi", "english", "tamil", "telugu", "2d", "3d", "m-ticket", "total"]
        let lines = body
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        if let rated = lines.first(where: {
            $0.range(of: #"^.+\([A-Z]{1,3}\)$"#, options: [.regularExpression, .caseInsensitive]) != nil
                && $0.count <= 48
        }) {
            fields["event"] = rated
        } else if let titled = lines.first(where: { line in
            let lower = line.lowercased()
            guard line.count >= 2, line.count <= 48 else { return false }
            guard line.rangeOfCharacter(from: .letters) != nil else { return false }
            guard !skipEvent.contains(where: { lower.contains($0) }) else { return false }
            guard line.range(of: #"\d{1,2}:\d{2}"#, options: .regularExpression) == nil else { return false }
            return true
        }) {
            fields["event"] = titled
        }

        // Append language/format to event when present on next lines
        if let event = fields["event"], !event.isEmpty {
            let format = lines.first(where: {
                $0.range(of: #"(?i)^(Hindi|English|Tamil|Telugu|Kannada|Malayalam).*(2D|3D|IMAX)|^(2D|3D|IMAX)$"#, options: .regularExpression) != nil
            })
            if let format, !event.localizedCaseInsensitiveContains(format) {
                fields["event"] = "\(event) · \(format)"
            }
        }

        if fields["qr_data"]?.isEmpty != false, let booking = fields["booking_id"], !booking.isEmpty {
            fields["qr_data"] = booking
        }

        return fields
    }

    /// Real cinema seats only — never "SCREEN 2".
    static func cinemaSeatList(from body: String) -> String? {
        let candidates: [String] = [
            // District: "QR - A5, B6" / "QR: A5, B6"
            #"(?i)(?:qr|seats?)\s*[-–:]\s*((?:[A-Z]{1,3}-)?[A-Z]\d{1,2}(?:\s*[,/]\s*(?:[A-Z]{1,3}-)?[A-Z]?\d{1,2})+)"#,
            // "Seats: A5, B6" / "Seat No. PC-F6, F7"
            #"(?i)seats?\s*(?:no\.?|numbers?)?\s*[:\-]?\s*((?:[A-Z]{1,3}-)?[A-Z]\d{1,2}(?:\s*[,/\s]\s*(?:[A-Z]{1,3}-)?[A-Z]?\d{1,2})*)"#,
            // Bare list "A5, B6" or "PC-F6, F7, F8" (require comma so "SCREEN 2" cannot match)
            #"(?i)\b((?:[A-Z]{1,3}-)?[A-Z]\d{1,2}(?:\s*,\s*(?:[A-Z]{1,3}-)?[A-Z]?\d{1,2})+)\b"#,
            // Single seat "A12" / "PC-F6" when labeled
            #"(?i)(?:seat|seats)\s*(?:no\.?)?\s*[:\-]?\s*((?:[A-Z]{1,3}-)?[A-Z]\d{1,2})\b"#
        ]
        for pattern in candidates {
            if let raw = TicketText.firstMatch(in: body, pattern: pattern) {
                var cleaned = raw.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .uppercased()
                // Reject auditorium / chrome false positives.
                let compact = cleaned.replacingOccurrences(of: " ", with: "")
                if compact.hasPrefix("SCREEN") { continue }
                if cleaned.range(of: #"^[A-Z]{0,3}\d{1,2}([,/ ][A-Z]{0,3}\d{1,2})*$"#, options: .regularExpression) == nil,
                   cleaned.range(of: #"^(?:[A-Z]{1,3}-)?[A-Z]\d{1,2}(?:\s*,\s*(?:[A-Z]{1,3}-)?[A-Z]?\d{1,2})*$"#, options: .regularExpression) == nil {
                    // Allow "PC-F6, F7" style already captured; only skip obvious junk.
                    if cleaned.contains("SCREEN") || cleaned.contains("TICKET") { continue }
                }
                if cleaned.count >= 2 { return cleaned }
            }
        }
        return nil
    }

    static func cinemaRelevantDate(from show: String) -> String? {
        let datePart = TicketText.firstMatch(
            in: show,
            pattern: #"(?i)(\d{1,2}\s+(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\.?)"#
        )
        let timePart = TicketText.firstMatch(in: show, pattern: #"(\d{1,2}:\d{2}\s*(?:AM|PM))"#)
        if let datePart, let timePart, let d = TicketText.parseShowDateTime(datePart, timePart) ?? TicketText.parseFlexibleDateTime(datePart, timePart) {
            return ISO8601DateFormatter().string(from: d.addingTimeInterval(-2 * 3600))
        }
        return nil
    }






}
