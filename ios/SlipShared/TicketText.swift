import Foundation

/// Shared OCR / regex helpers used by per-brand pass handlers.
enum TicketText {
    static func firstMatch(in text: String, pattern: String) -> String? {
        matches(in: text, pattern: pattern).first
    }

    static func matches(in text: String, pattern: String) -> [String] {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        return regex.matches(in: text, range: range).compactMap { match in
            guard match.numberOfRanges > 1,
                  let r = Range(match.range(at: 1), in: text) else { return nil }
            return String(text[r]).trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }

    static func upiQueryValue(_ qr: String, key: String) -> String? {
        guard let comps = URLComponents(string: qr) else { return nil }
        return comps.queryItems?.first(where: { $0.name == key })?.value?
            .removingPercentEncoding
    }

    static func parseLooseDate(_ raw: String) -> Date? {
        let formats = [
            "dd/MM/yyyy", "dd-MM-yyyy", "dd/MM/yy", "d/M/yyyy",
            "dd-MMM-yyyy", "dd MMM yyyy", "d-MMM-yyyy", "d MMM yyyy",
            "EEE, d MMM yyyy", "EEE, dd MMM yyyy", "EEE, d MMM yy", "EEE, dd MMM yy",
            "EEE, d MMM", "EEE, dd MMM",
            "d MMM yy", "dd MMM yy",
            "yyyy-MM-dd"
        ]
        let parser = DateFormatter()
        parser.locale = Locale(identifier: "en_IN")
        for f in formats {
            parser.dateFormat = f
            if let d = parser.date(from: raw) { return d }
        }
        return nil
    }

    static func parseLooseDateTime(_ raw: String) -> Date? {
        let cleaned = raw
            .replacingOccurrences(of: "-", with: " ")
            .replacingOccurrences(of: "/", with: " ")
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let formats = [
            "dd MMM yyyy HH:mm",
            "dd MMMM yyyy HH:mm",
            "d MMM yyyy HH:mm",
            "dd MMM yyyy H:mm",
            "yyyy MM dd HH:mm"
        ]
        let parser = DateFormatter()
        parser.locale = Locale(identifier: "en_IN")
        for f in formats {
            parser.dateFormat = f
            if let d = parser.date(from: cleaned) { return d }
        }
        return parseLooseDate(raw)
    }

    static func parseShowDateTime(_ datePart: String, _ timePart: String) -> Date? {
        let formats = [
            "dd-MMM-yyyy HH:mm",
            "dd-MM-yyyy HH:mm",
            "yyyy-MM-dd HH:mm",
            "dd-MMM-yyyy h:mm a",
            "dd MMM yyyy HH:mm",
            "dd MMM yyyy h:mm a",
            "d MMM yyyy h:mm a"
        ]
        let parser = DateFormatter()
        parser.locale = Locale(identifier: "en_IN")
        let combined = "\(datePart) \(timePart)"
        for f in formats {
            parser.dateFormat = f
            if let d = parser.date(from: combined) { return d }
        }
        return parseLooseDate(datePart)
    }

    static func parseFlexibleDateTime(_ datePart: String, _ timePart: String) -> Date? {
        let formats = [
            "EEE, dd MMM h:mm a", "EEE, d MMM h:mm a",
            "EEE, dd MMM hh:mm a", "EEE, d MMM hh:mm a",
            "EEE, dd MMM yyyy h:mm a", "EEE, d MMM yyyy h:mm a",
            "dd MMM h:mm a", "d MMM h:mm a",
            "dd MMM yyyy h:mm a", "d MMM yyyy h:mm a"
        ]
        let parser = DateFormatter()
        parser.locale = Locale(identifier: "en_IN")
        parser.timeZone = TimeZone(identifier: "Asia/Kolkata")
        let combined = "\(datePart) \(timePart)"
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
        for f in formats {
            parser.dateFormat = f
            if let d = parser.date(from: combined) {
                var cal = Calendar(identifier: .gregorian)
                cal.timeZone = TimeZone(identifier: "Asia/Kolkata") ?? .current
                let year = cal.component(.year, from: Date())
                var comps = cal.dateComponents([.month, .day, .hour, .minute], from: d)
                comps.year = year
                if let stamped = cal.date(from: comps) {
                    if stamped < Date().addingTimeInterval(-60 * 24 * 3600) {
                        comps.year = year + 1
                        return cal.date(from: comps)
                    }
                    return stamped
                }
                return d
            }
        }
        return parseShowDateTime(datePart, timePart)
    }

    static func result(
        templateId: String,
        displayName: String,
        confidence: Double,
        fields: [String: String],
        stationIds: [String] = [],
        relevantDateISO8601: String? = nil,
        rationale: String,
        ticket: ExtractedTicket
    ) -> ClassificationResult {
        ClassificationResult(
            templateId: templateId,
            displayName: displayName,
            confidence: confidence,
            fields: fields,
            stationIds: stationIds,
            relevantDateISO8601: relevantDateISO8601,
            rationale: rationale,
            needsManualBrandPick: confidence < 0.5,
            extracted: ticket,
            createdAt: Date()
        )
    }

    static func unknown(ticket: ExtractedTicket, qr: String) -> ClassificationResult {
        var fields: [String: String] = [:]
        if !qr.isEmpty { fields["qr_data"] = qr }
        return ClassificationResult(
            templateId: "",
            displayName: "Unknown",
            confidence: 0.15,
            fields: fields,
            stationIds: [],
            relevantDateISO8601: nil,
            rationale: "Could not match a brand from screenshot text. Pick one from the marketplace.",
            needsManualBrandPick: true,
            extracted: ticket,
            createdAt: Date()
        )
    }
}
