import Foundation

struct DiningPassHandler: BrandPassHandler {
    enum Brand {
        case easydiner, zomato, swiggy
        var id: String {
            switch self {
            case .easydiner: return "easydiner"
            case .zomato: return "zomato-dineout"
            case .swiggy: return "swiggy-dineout"
            }
        }
        var priority: Int {
            switch self {
            case .easydiner: return 30
            case .zomato: return 31
            case .swiggy: return 32
            }
        }
    }

    static let easydiner = DiningPassHandler(brand: .easydiner)
    static let zomato = DiningPassHandler(brand: .zomato)
    static let swiggy = DiningPassHandler(brand: .swiggy)

    let brand: Brand
    var templateId: String { brand.id }
    var priority: Int { brand.priority }

    func matches(qr: String, hay: String, ticket: ExtractedTicket) -> Bool { true }

    func classify(qr: String, hay: String, ticket: ExtractedTicket) -> ClassificationResult? {
        guard let result = DiningPassLogic.classify(qr: qr, hay: hay, ticket: ticket) else { return nil }
        // Only claim the result if template matches this handler instance.
        return result.templateId == templateId ? result : nil
    }

    func enrich(_ result: ClassificationResult) -> ClassificationResult {
        var result = result
        let qr = result.fields["qr_data"] ?? result.extracted.qrPayload ?? ""
        let parsed = DiningPassLogic.extractFields(from: result.extracted.recognizedText, qr: qr)
        for (key, value) in parsed {
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            let existing = result.fields[key]?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if existing.isEmpty, !trimmed.isEmpty {
                result.fields[key] = trimmed
            }
        }
        let restaurant = result.fields["restaurant"]?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if restaurant.isEmpty {
            if let event = result.fields["event"]?.trimmingCharacters(in: .whitespacesAndNewlines), !event.isEmpty {
                result.fields["restaurant"] = event
            } else {
                let dn = result.displayName.trimmingCharacters(in: .whitespacesAndNewlines)
                let brandish = ["easydiner", "eazy diner", "zomato", "swiggy", "dineout"]
                if !dn.isEmpty, !brandish.contains(where: { dn.lowercased().contains($0) }) {
                    result.fields["restaurant"] = dn
                }
            }
        }
        var booking = result.fields["booking_id"]?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if ["irmed", "confirm", "confirmed"].contains(booking.lowercased()) {
            booking = ""
            result.fields["booking_id"] = ""
        }
        let q = result.fields["qr_data"]?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if booking.isEmpty {
            let again = DiningPassLogic.extractFields(from: result.extracted.recognizedText, qr: q)
            if let bid = again["booking_id"], !bid.isEmpty, bid.lowercased() != "irmed" {
                booking = bid
                result.fields["booking_id"] = bid
            }
        }
        if q.isEmpty, !booking.isEmpty {
            result.fields["qr_data"] = booking
        }
        if result.displayName.lowercased() == result.templateId
            || ["easydiner", "zomato dineout", "swiggy dineout"].contains(result.displayName.lowercased()),
           let restaurant = result.fields["restaurant"], !restaurant.isEmpty {
            result.displayName = restaurant
        }
        return result
    }

    func prefersRules(over ai: ClassificationResult, rules: ClassificationResult) -> Bool {
        let theatreIds: Set<String> = ["bookmyshow", "district"]
        let diningIds: Set<String> = ["easydiner", "zomato-dineout", "swiggy-dineout"]
        return diningIds.contains(rules.templateId)
            && rules.confidence >= 0.7
            && (theatreIds.contains(ai.templateId) || ai.templateId.isEmpty
                || (diningIds.contains(ai.templateId) && rules.confidence >= ai.confidence))
    }
}

enum DiningPassLogic {
    static func classify(qr: String, hay: String, ticket: ExtractedTicket) -> ClassificationResult? {
        let h = hay.lowercased()
        // Reject clear cinema / event tickets — those belong to BookMyShow / District.
        let cinemaCue = h.contains("bookmyshow") || h.contains("m-ticket") || h.contains("mticket")
            || h.contains("inox") || h.contains("cinepolis") || h.contains("pvr")
            || (h.contains("screen") && (h.contains("seat") || h.contains("cinema") || h.contains("theatre") || h.contains("theater")))
            || h.contains("imax")
        if cinemaCue { return nil }

        let brandedEazy = h.contains("easydiner") || h.contains("eazydiner") || h.contains("easy diner")
        // Zomato confirmation UI often OCRs without the word "Zomato".
        let zomatoLayout = (h.contains("booking confirmed") || h.contains("reach restaurant"))
            && (h.contains("guest") || h.contains("guests"))
            && (h.contains("pay bill") || h.contains("cashback") || h.contains("invite guests")
                || h.contains("convenience fee") || h.contains("date and time") || h.contains("number of guest"))
        let brandedZomato = zomatoLayout
            || (h.contains("zomato") && (h.contains("dineout") || h.contains("dine out") || h.contains("reservation")
                || h.contains("table") || h.contains("booking confirmed") || h.contains("pay bill")))
        // Swiggy Dineout confirmation often OCRs "Dineout" / "DineCash" without the word "Swiggy".
        let swiggyLayout = h.contains("your table is booked")
            || h.contains("pay bill now")
            || h.contains("dinecash")
            || h.contains("new on dineout")
            || (h.contains("swiggy") && (h.contains("dineout") || h.contains("dine out") || h.contains("table")))
        let brandedSwiggy = swiggyLayout && !zomatoLayout
        // EazyDiner booking-details UI often omits the brand logo text in OCR.
        let eazyLayout = (h.contains("booking completed") || h.contains("book again") || h.contains("restaurant offer"))
            && (h.contains("guests") || h.contains("guest"))
            && (h.contains("booking id") || h.contains("bookingid"))
        let genericDining = (h.contains("guests") || h.contains("pax") || h.contains("covers") || h.contains("for "))
            && (h.contains("table") || h.contains("restaurant") || h.contains("dining") || h.contains("dinner") || h.contains("lunch"))
            && (h.contains("confirmed") || h.contains("booked") || h.contains("reservation") || h.contains("booking"))

        let templateId: String
        let displayName: String
        let confidence: Double
        if brandedZomato {
            templateId = "zomato-dineout"; displayName = "Zomato Dineout"; confidence = zomatoLayout ? 0.92 : 0.88
        } else if brandedSwiggy {
            templateId = "swiggy-dineout"; displayName = "Swiggy Dineout"; confidence = 0.9
        } else if brandedEazy || eazyLayout {
            templateId = "easydiner"; displayName = "EazyDiner"; confidence = brandedEazy ? 0.92 : 0.86
        } else if h.contains("dineout") || h.contains("dine out") {
            templateId = "swiggy-dineout"; displayName = "Swiggy Dineout"; confidence = 0.78
        } else if genericDining {
            templateId = "easydiner"; displayName = "EazyDiner"; confidence = 0.72
        } else {
            return nil
        }

        var fields = extractFields(from: ticket.recognizedText, qr: qr)
        // Synthesize a stable booking id when the UI has none (Swiggy Dineout confirmations).
        if (fields["booking_id"] ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            if let synth = synthesizeDiningBookingId(restaurant: fields["restaurant"], time: fields["time"], text: ticket.recognizedText) {
                fields["booking_id"] = synth
                if fields["qr_data"] == nil { fields["qr_data"] = synth }
            }
        }
        guard fields["restaurant"] != nil || fields["booking_id"] != nil || fields["qr_data"] != nil else {
            return nil
        }

        let title = fields["restaurant"]?.trimmingCharacters(in: .whitespacesAndNewlines)
        let shown = (title?.isEmpty == false) ? title! : displayName
        return TicketText.result(
            templateId: templateId,
            displayName: shown,
            confidence: confidence,
            fields: fields,
            stationIds: [],
            relevantDateISO8601: diningRelevantDate(from: ticket.recognizedText, time: fields["time"]),
            rationale: "Matched \(displayName) restaurant reservation (not a theatre ticket).",
            ticket: ticket
        )
    }

    /// Shared dining field parser — also used to backfill Apple Intelligence drafts.
    static func extractFields(from text: String, qr: String) -> [String: String] {
        var fields: [String: String] = [:]
        if !qr.isEmpty { fields["qr_data"] = qr }

        // Prefer explicit Booking ID. Never treat the word "Confirmed" as an id ("conf"+"irmed").
        if let booking = TicketText.firstMatch(in: text, pattern: #"(?i)booking\s*id\s*[:\-]?\s*([A-Z0-9][A-Z0-9\-]{4,})"#)
            ?? TicketText.firstMatch(in: text, pattern: #"(?i)(?:reservation|confirmation)\s*(?:id|no\.?|#|code)\s*[:\-]?\s*([A-Z0-9][A-Z0-9\-]{4,})"#) {
            let cleaned = booking.trimmingCharacters(in: .whitespacesAndNewlines)
            let junk: Set<String> = ["irmed", "irmed!", "irmed.", "irmed,", "irmed)", "confirmed", "confirm"]
            if !junk.contains(cleaned.lowercased()), cleaned.lowercased() != "irmed" {
                fields["booking_id"] = cleaned
                if fields["qr_data"] == nil { fields["qr_data"] = cleaned }
            }
        }

        if let restaurant = TicketText.firstMatch(in: text, pattern: #"(?i)(?:restaurant|venue|outlet)\s*[:\-]?\s*([^\n]{3,60})"#) {
            fields["restaurant"] = restaurant.trimmingCharacters(in: .whitespacesAndNewlines)
        } else if let named = diningRestaurantName(from: text) {
            fields["restaurant"] = named
        }

        // Swiggy: "Dinner, 07:30 PM for 2 guests" / Zomato: "30 Sep at 6:45 PM"
        if let mealTime = TicketText.firstMatch(in: text, pattern: #"(?i)(?:dinner|lunch|breakfast|brunch)\s*,\s*((?:[01]?\d|2[0-3])[:.][0-5]\d\s*(?:AM|PM))"#) {
            fields["time"] = mealTime.trimmingCharacters(in: .whitespaces)
        } else if let zomatoWhen = TicketText.firstMatch(
            in: text,
            pattern: #"(?i)(?:date\s*and\s*time|date|time)\s*[:\-]?\s*(\d{1,2}\s+(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\.?(?:\s+at\s+)?\d{1,2}:\d{2}\s*(?:AM|PM))"#
        ) ?? TicketText.firstMatch(
            in: text,
            pattern: #"(?i)(\d{1,2}\s+(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\.?\s+at\s+\d{1,2}:\d{2}\s*(?:AM|PM))"#
        ) {
            fields["time"] = zomatoWhen.trimmingCharacters(in: .whitespacesAndNewlines)
        } else if let time = TicketText.firstMatch(in: text, pattern: #"(?i)(?:time|slot)\s*[:\-]?\s*((?:[01]?\d|2[0-3])[:.][0-5]\d\s*(?:AM|PM|am|pm)?)"#)
            ?? TicketText.firstMatch(in: text, pattern: #"\b((?:[01]?\d|2[0-3])[:.][0-5]\d\s*(?:AM|PM))\b"#) {
            fields["time"] = time.trimmingCharacters(in: .whitespaces)
        }

        if let party = TicketText.firstMatch(in: text, pattern: #"(?i)(?:number\s*of\s*guest(?:\(s\))?|guests?)\s*[:\-]?\s*(\d{1,2})\b"#)
            ?? TicketText.firstMatch(in: text, pattern: #"(?i)(\d{1,2})\s+guests?\b"#)
            ?? TicketText.firstMatch(in: text, pattern: #"(?i)for\s+(\d{1,2})\s+guests?\b"#)
            ?? TicketText.firstMatch(in: text, pattern: #"(?i)(?:pax|party|covers)\s*[:\-]?\s*(\d{1,2})\b"#) {
            fields["party_size"] = party
        }

        return fields
    }

    static func synthesizeDiningBookingId(restaurant: String?, time: String?, text: String) -> String? {
        let name = (restaurant ?? "")
            .uppercased()
            .replacingOccurrences(of: #"[^A-Z0-9]+"#, with: "", options: .regularExpression)
        let compact = String(name.prefix(8))
        let clock = (time ?? "")
            .uppercased()
            .replacingOccurrences(of: #"[^0-9APM]"#, with: "", options: .regularExpression)
        let day = TicketText.firstMatch(in: text, pattern: #"(?i)(\d{1,2}\s+(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\.?\s+\d{2,4})"#)
            ?? TicketText.firstMatch(in: text, pattern: #"(?i)today"#)
            ?? ""
        let dayKey = day.uppercased().replacingOccurrences(of: #"[^A-Z0-9]+"#, with: "", options: .regularExpression)
        let seed = [compact, String(dayKey.prefix(9)), String(clock.prefix(6))]
            .filter { !$0.isEmpty }
            .joined(separator: "-")
        guard seed.count >= 6 else { return nil }
        return "DIN-" + seed
    }

    /// Pull restaurant title from EazyDiner-style layouts (name above locality line).
    static func diningRestaurantName(from text: String) -> String? {
        let lines = text
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        let skipPrefixes = [
            "booking", "date", "time", "guest", "offer", "get direction", "book again",
            "restaurant offer", "contact", "call", "share", "status", "completed", "details",
            "confirmed", "booking confirmed", "your table", "pay bill", "earn ", "new on", "need help", "done",
            "reach restaurant", "convenience", "invite guests", "let anyone", "benefit", "location",
            "date and time", "number of guest", "cashback",
            "dinner,", "lunch,", "breakfast,", "brunch,",
            "whitefield,", "east bengaluru", "bengaluru", "bangalore", "mumbai", "delhi", "hyderabad",
            "marathahalli,", "koramangala,", "indiranagar,"
        ]
        let locality = #"(?i).+,\s*(east |west |north |south )?(bengaluru|bangalore|mumbai|delhi|hyderabad|chennai|pune|kolkata).*"#

        for (idx, line) in lines.enumerated() {
            let lower = line.lowercased()
            if skipPrefixes.contains(where: { lower.hasPrefix($0) }) { continue }
            if lower.range(of: #"^\+?\d[\d\s\-]{8,}$"#, options: .regularExpression) != nil { continue }
            if lower.range(of: #"^\d{1,2}[:.]\d{2}"#, options: .regularExpression) != nil { continue }
            if line.count < 3 || line.count > 48 { continue }
            // Prefer the line immediately above a locality / area line.
            if idx + 1 < lines.count,
               lines[idx + 1].range(of: locality, options: .regularExpression) != nil {
                return line
            }
        }

        // Prefer ALL-CAPS venue titles (Zomato: "OASIS BREWERY").
        if let caps = lines.first(where: { line in
            let letters = line.filter { $0.isLetter }
            guard letters.count >= 4, letters.count <= 40 else { return false }
            guard letters.allSatisfy({ $0.isUppercase }) else { return false }
            let lower = line.lowercased()
            return !skipPrefixes.contains(where: { lower.hasPrefix($0) })
                && !lower.contains("booking")
                && !lower.contains("confirmed")
        }) {
            return caps
        }

        // Fallback: first non-boilerplate title-ish line after confirmation headers.
        if let start = lines.firstIndex(where: {
            let l = $0.lowercased()
            return l.contains("booking completed")
                || l.contains("booking confirmed")
                || l == "booking details"
                || l.contains("your table is booked")
                || l == "confirmed"
        }) {
            for line in lines.dropFirst(start + 1).prefix(6) {
                let lower = line.lowercased()
                if skipPrefixes.contains(where: { lower.hasPrefix($0) }) { continue }
                if lower.contains("booking id") { continue }
                if line.count >= 3, line.count <= 48 { return line }
            }
        }
        return nil
    }


    static func diningRelevantDate(from text: String, time: String?) -> String? {
        let dateRaw = TicketText.firstMatch(
            in: text,
            pattern: #"(?i)(?:today|tomorrow)\s*,\s*(\d{1,2}\s+(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\.?\s+\d{2,4})"#
        ) ?? TicketText.firstMatch(
            in: text,
            pattern: #"(?i)((?:Mon|Tue|Wed|Thu|Fri|Sat|Sun)[a-z]*,?\s+\d{1,2}\s+(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\.?\s+\d{2,4})"#
        ) ?? TicketText.firstMatch(
            in: text,
            pattern: #"(?i)(\d{1,2}\s+(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\.?\s+\d{2,4})"#
        ) ?? TicketText.firstMatch(
            in: text,
            pattern: #"(?i)(\d{1,2}\s+(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\.?)(?:\s+at\s+\d{1,2}:\d{2}\s*(?:AM|PM))?"#
        )
        var day: Date?
        if let dateRaw {
            day = TicketText.parseLooseDate(dateRaw) ?? TicketText.parseFlexibleDateTime(dateRaw, "12:00 PM")
        }
        // Zomato often has "30 Sep at 6:45 PM" — pin year if missing.
        if day == nil, let md = TicketText.firstMatch(in: text, pattern: #"(?i)(\d{1,2}\s+(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\.?)"#),
           let clock = TicketText.firstMatch(in: text, pattern: #"(?i)at\s+(\d{1,2}:\d{2}\s*(?:AM|PM))"#) {
            day = TicketText.parseFlexibleDateTime(md, clock)
        }
        guard var day else { return nil }

        if let time {
            let upper = time.uppercased()
            if let hm = TicketText.firstMatch(in: upper, pattern: #"([01]?\d|2[0-3])[:.]([0-5]\d)"#) {
                let bits = hm.replacingOccurrences(of: ".", with: ":").split(separator: ":")
                if bits.count >= 2, var hour = Int(bits[0]), let minute = Int(bits[1]) {
                    if upper.contains("PM"), hour < 12 { hour += 12 }
                    if upper.contains("AM"), hour == 12 { hour = 0 }
                    var cal = Calendar(identifier: .gregorian)
                    cal.timeZone = TimeZone(identifier: "Asia/Kolkata") ?? .current
                    if let stamped = cal.date(bySettingHour: hour, minute: minute, second: 0, of: day) {
                        day = stamped
                    }
                }
            }
        }
        return ISO8601DateFormatter().string(from: day)
    }

}
