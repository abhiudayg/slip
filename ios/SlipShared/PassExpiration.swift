import Foundation

/// Derives relevant / expiration dates for Slip vault + Apple Wallet.
enum PassExpiration {
    /// When the pass should leave the active Lock Screen / Active list.
    static func expiresAt(
        templateId: String,
        fields: [String: String],
        relevantDateISO8601: String? = nil
    ) -> Date? {
        switch templateId {
        case "airbnb":
            // Stay valid through check-out day (end of local day).
            if let checkout = parseFlexibleDate(fields["check_out"]) {
                return endOfDay(checkout)
            }
            if let checkin = parseFlexibleDate(fields["check_in"]) {
                return endOfDay(checkin.addingTimeInterval(2 * 24 * 3600))
            }
        case "bookmyshow", "district", "easydiner", "zomato-dineout", "swiggy-dineout":
            if let start = parseFlexibleDate(fields["time"])
                ?? parseISO8601(relevantDateISO8601) {
                return start.addingTimeInterval(4 * 3600)
            }
        case "irctc", "indigo", "redbus", "namma-metro":
            if let dep = parseFlexibleDate(fields["dep"])
                ?? parseFlexibleDate(fields["departure"])
                ?? parseFlexibleDate(fields["time"])
                ?? parseISO8601(relevantDateISO8601) {
                return dep.addingTimeInterval(12 * 3600)
            }
        case "zoomcar":
            if let pickup = parseFlexibleDate(fields["pickup"]) {
                return pickup.addingTimeInterval(24 * 3600)
            }
        case "upi":
            return nil // UPI QR stays active until deleted
        default:
            break
        }

        if let relevant = parseISO8601(relevantDateISO8601) {
            return relevant.addingTimeInterval(6 * 3600)
        }
        return nil
    }

    /// Best Lock Screen `relevantDate` for PassKit.
    static func relevantDateISO8601(
        templateId: String,
        fields: [String: String],
        existing: String? = nil
    ) -> String? {
        if let existing, parseISO8601(existing) != nil { return existing }

        let candidates: [String?]
        switch templateId {
        case "airbnb":
            candidates = [fields["check_in"], fields["check_out"]]
        case "bookmyshow", "district", "easydiner", "zomato-dineout", "swiggy-dineout":
            candidates = [fields["time"]]
        case "irctc", "indigo", "redbus", "namma-metro":
            candidates = [fields["dep"], fields["departure"], fields["time"]]
        case "zoomcar":
            candidates = [fields["pickup"]]
        default:
            candidates = [fields["time"], fields["check_in"], fields["dep"]]
        }

        for raw in candidates {
            if let date = parseFlexibleDate(raw) {
                return iso8601String(from: date)
            }
        }
        return nil
    }

    static func isExpired(_ expiresAt: Date?, now: Date = Date()) -> Bool {
        guard let expiresAt else { return false }
        return expiresAt <= now
    }

    static func iso8601String(from date: Date) -> String {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f.string(from: date)
    }

    static func parseISO8601(_ raw: String?) -> Date? {
        guard let raw, !raw.isEmpty else { return nil }
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = f.date(from: raw) { return d }
        f.formatOptions = [.withInternetDateTime]
        return f.date(from: raw)
    }

    /// Parses loose ticket strings like "Fri, Oct 2 After 1:00 PM", "Oct 2, 2025", ISO, etc.
    static func parseFlexibleDate(_ raw: String?) -> Date? {
        guard var text = raw?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty else {
            return nil
        }
        if let iso = parseISO8601(text) { return iso }

        // Strip prefixes like "After" / "By"
        text = text
            .replacingOccurrences(of: #"(?i)\b(after|by|before)\b"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let styles: [DateFormatter] = {
            let locales = [Locale(identifier: "en_US_POSIX"), Locale.current]
            let patterns = [
                "EEE, MMM d h:mm a",
                "EEE, MMM d 'at' h:mm a",
                "EEE, MMM d yyyy h:mm a",
                "MMM d, yyyy h:mm a",
                "MMM d yyyy h:mm a",
                "MMM d, yyyy",
                "MMM d yyyy",
                "EEE, MMM d",
                "MMM d",
                "yyyy-MM-dd'T'HH:mm:ssZ",
                "yyyy-MM-dd HH:mm",
                "yyyy-MM-dd"
            ]
            var formatters: [DateFormatter] = []
            for locale in locales {
                for pattern in patterns {
                    let f = DateFormatter()
                    f.locale = locale
                    f.timeZone = .current
                    f.dateFormat = pattern
                    formatters.append(f)
                }
            }
            return formatters
        }()

        for f in styles {
            if let date = f.date(from: text) {
                return inferYearIfNeeded(date, from: text)
            }
        }
        return nil
    }

    private static func inferYearIfNeeded(_ date: Date, from text: String) -> Date {
        // If the string had no year, DateFormatter may use 2000 / current — bump to upcoming occurrence.
        let hasYear = text.range(of: #"\b20\d{2}\b"#, options: .regularExpression) != nil
        guard !hasYear else { return date }

        var comps = Calendar.current.dateComponents([.month, .day, .hour, .minute], from: date)
        let now = Date()
        comps.year = Calendar.current.component(.year, from: now)
        guard var candidate = Calendar.current.date(from: comps) else { return date }
        if candidate < now.addingTimeInterval(-24 * 3600) {
            comps.year = (comps.year ?? 0) + 1
            candidate = Calendar.current.date(from: comps) ?? candidate
        }
        return candidate
    }

    private static func endOfDay(_ date: Date) -> Date {
        let cal = Calendar.current
        let start = cal.startOfDay(for: date)
        return cal.date(byAdding: DateComponents(day: 1, second: -1), to: start) ?? date
    }
}
