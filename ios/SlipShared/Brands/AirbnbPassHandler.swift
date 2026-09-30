import Foundation

struct AirbnbPassHandler: BrandPassHandler {
    let templateId = "airbnb"
    let priority = 100
    func matches(qr: String, hay: String, ticket: ExtractedTicket) -> Bool { true }
    func classify(qr: String, hay: String, ticket: ExtractedTicket) -> ClassificationResult? {
        AirbnbPassLogic.classify(qr: qr, hay: hay, ticket: ticket)
    }
    func enrich(_ result: ClassificationResult) -> ClassificationResult {
        var result = result
        if result.displayName.lowercased() == "airbnb" || result.displayName.isEmpty,
           let property = result.fields["property"], !property.isEmpty {
            result.displayName = property
        }
        return result
    }
}

enum AirbnbPassLogic {
    static func classify(qr: String, hay: String, ticket: ExtractedTicket) -> ClassificationResult? {
        let h = hay.lowercased()
        let text = ticket.recognizedText
        let looksLikeAirbnbEmail =
            h.contains("reservation reminder")
            && (h.contains("hosted by") || h.contains("entire home") || h.contains("pack your bags"))
        guard h.contains("airbnb") || h.contains("airbnb.com") || looksLikeAirbnbEmail else { return nil }

        var fields: [String: String] = [:]
        if !qr.isEmpty { fields["qr_data"] = qr }

        // Confirmation / reservation code (Airbnb codes are typically 8–10 alphanumerics).
        if let booking = TicketText.firstMatch(
            in: text,
            pattern: #"(?i)(?:reservation|confirmation)\s*code\s*[:\-]?\s*([A-Z0-9]{6,12})"#
        ) ?? TicketText.firstMatch(
            in: text,
            pattern: #"(?i)(?:confirmation|reservation)\s*(?:code|id)?\s*[:\-]?\s*([A-Z0-9]{8,12})"#
        ) {
            let code = booking.uppercased()
            fields["booking_id"] = code
            if fields["qr_data"] == nil { fields["qr_data"] = code }
        }

        if let property = airbnbPropertyName(from: text) {
            fields["property"] = property
        }

        if let checkIn = airbnbLabeledValue(in: text, labels: ["check-in", "check in", "checkin"]) {
            fields["check_in"] = checkIn
        }
        if let checkOut = airbnbLabeledValue(in: text, labels: ["check-out", "check out", "checkout"]) {
            fields["check_out"] = checkOut
        }

        if let guests = TicketText.firstMatch(in: text, pattern: #"(?i)guests?\s*[:\-]?\s*\n\s*([0-9]+\s*adults?[^\n]*)"#)
            ?? TicketText.firstMatch(in: text, pattern: #"(?i)([0-9]+\s*adults?(?:\s*[,·]\s*[0-9]+\s*children?)?)"#) {
            fields["guest"] = guests
        }

        guard fields["qr_data"] != nil || fields["property"] != nil else { return nil }

        let relevant = TicketText.parseLooseDate(fields["check_in"] ?? "")
        let relevantISO: String? = {
            guard let relevant else { return nil }
            return ISO8601DateFormatter().string(from: relevant)
        }()

        return TicketText.result(
            templateId: "airbnb",
            displayName: "Airbnb",
            confidence: 0.88,
            fields: fields,
            stationIds: [],
            relevantDateISO8601: relevantISO,
            rationale: "Matched Airbnb reservation.",
            ticket: ticket
        )
    }

    /// Listing title from Airbnb reminder emails — not the "Entire home/apt hosted by …" line.
    static func airbnbPropertyName(from text: String) -> String? {
        let lines = text
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        for (index, line) in lines.enumerated() {
            let lower = line.lowercased()
            let isStayType =
                lower.hasPrefix("entire home")
                || lower.hasPrefix("private room")
                || lower.hasPrefix("hotel room")
                || lower.hasPrefix("shared room")
                || (lower.contains("hosted by") && (lower.contains("home") || lower.contains("apt") || lower.contains("room")))
            guard isStayType else { continue }

            var candidate: String?
            var j = index - 1
            while j >= 0 {
                let prev = lines[j]
                let pl = prev.lowercased()
                if pl.contains("trip to") || pl.hasPrefix("pack your") || pl.contains("airbnb") {
                    break
                }
                // Skip short location crumbs like "in city,"
                if pl.hasPrefix("in ") && prev.count < 24 {
                    j -= 1
                    continue
                }
                if prev.count >= 4 {
                    candidate = prev
                    break
                }
                j -= 1
            }
            if let candidate {
                // "Dee Amour is a charming old tiled house" → "Dee Amour"
                if let range = candidate.range(of: " is ", options: .caseInsensitive) {
                    let short = String(candidate[..<range.lowerBound]).trimmingCharacters(in: .whitespaces)
                    if short.count >= 3 { return String(short.prefix(48)) }
                }
                return String(candidate.prefix(60))
            }
        }

        if let city = TicketText.firstMatch(in: text, pattern: #"(?i)trip to\s+([^\n\.]+)"#) {
            return city.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        if let listing = TicketText.firstMatch(in: text, pattern: #"(?i)(?:listing|property|stay)\s*[:\-]\s*(.+)"#) {
            return String(listing.prefix(60))
        }
        return nil
    }

    /// Airbnb labels often sit alone on a line with the value on the next line(s).
    static func airbnbLabeledValue(in text: String, labels: [String]) -> String? {
        let lines = text
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        let stoppers = Set([
            "address", "guests", "amount", "getting inside", "house rules",
            "reservation code", "view receipt", "invite guests", "show more",
            "check-in", "check in", "checkin", "check-out", "check out", "checkout"
        ])

        for (index, line) in lines.enumerated() {
            let lower = line.lowercased()
            for label in labels {
                let isExact = lower == label
                let hasPrefix = lower.hasPrefix(label + ":") || lower.hasPrefix(label + " ")
                guard isExact || hasPrefix else { continue }

                if let range = line.range(of: label, options: [.caseInsensitive, .anchored]) {
                    let after = String(line[range.upperBound...])
                        .trimmingCharacters(in: CharacterSet(charactersIn: ":–-• ").union(.whitespacesAndNewlines))
                    if after.count >= 3 { return after }
                }

                var parts: [String] = []
                var j = index + 1
                while j < lines.count && parts.count < 2 {
                    let next = lines[j]
                    let nl = next.lowercased()
                    if stoppers.contains(nl) || labels.contains(where: { nl == $0 || nl.hasPrefix($0 + " ") }) {
                        break
                    }
                    if next.count >= 3 { parts.append(next) }
                    j += 1
                }
                if !parts.isEmpty {
                    return parts.joined(separator: " · ")
                }
            }
        }
        return nil
    }


}
