import Foundation

enum PassAccessibility {
    static func summary(brandId: String, displayName: String, fields: [String: String]) -> String {
        var parts: [String] = [displayName.isEmpty ? brandId : displayName]
        switch brandId {
        case "bookmyshow", "district":
            if let seat = nonEmpty(fields["seat"]) { parts.append("Seat \(seat)") }
            if let venue = nonEmpty(fields["venue"]) { parts.append(venue) }
            if let time = nonEmpty(fields["time"]) ?? nonEmpty(fields["date"]) { parts.append(time) }
        case "indigo", "irctc", "redbus", "namma-metro":
            if let o = nonEmpty(fields["origin"]), let d = nonEmpty(fields["destination"]) {
                parts.append("\(o) to \(d)")
            }
            if let seat = nonEmpty(fields["seat"]) { parts.append("Seat \(seat)") }
            if let flight = nonEmpty(fields["flight"]) { parts.append(flight) }
            if let train = nonEmpty(fields["train"]) { parts.append(train) }
        case "airbnb":
            if let property = nonEmpty(fields["property"]) { parts.append(property) }
            if nonEmpty(fields["door_pin"]) != nil { parts.append("Door PIN available") }
        case "upi", "easydiner", "zomato-dineout", "swiggy-dineout":
            if let name = nonEmpty(fields["name"]) ?? nonEmpty(fields["restaurant"]) { parts.append(name) }
            if let vpa = nonEmpty(fields["vpa"]) { parts.append("VPA \(vpa)") }
        default:
            break
        }
        if nonEmpty(fields["qr_data"]) != nil {
            parts.append("QR code ready to scan")
        }
        return parts.joined(separator: ", ")
    }

    private static func nonEmpty(_ value: String?) -> String? {
        guard let value else { return nil }
        let t = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return (t.isEmpty || t == "—") ? nil : t
    }
}
