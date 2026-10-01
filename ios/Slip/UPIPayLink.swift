import Foundation
import UIKit

/// Builds `upi://pay?...` deep links for GPay / PhonePe / Cred / any UPI app.
enum UPIPayLink {
    static func url(from fields: [String: String]) -> URL? {
        if let raw = fields["qr_data"]?.trimmingCharacters(in: .whitespacesAndNewlines),
           raw.lowercased().hasPrefix("upi://"),
           let url = URL(string: raw) {
            return url
        }
        let pa = first(fields, ["vpa", "payee_vpa", "pa"])
        guard let pa, !pa.isEmpty else { return nil }
        var items: [URLQueryItem] = [
            URLQueryItem(name: "pa", value: pa),
            URLQueryItem(name: "cu", value: "INR")
        ]
        if let pn = first(fields, ["name", "payee", "restaurant", "pn"]) {
            items.append(URLQueryItem(name: "pn", value: pn))
        }
        if let am = first(fields, ["amount", "am", "bill_amount"]) {
            let cleaned = am.replacingOccurrences(of: "₹", with: "")
                .replacingOccurrences(of: ",", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if !cleaned.isEmpty {
                items.append(URLQueryItem(name: "am", value: cleaned))
            }
        }
        if let tn = first(fields, ["note", "tn", "booking_id"]) {
            items.append(URLQueryItem(name: "tn", value: tn))
        }
        var components = URLComponents()
        components.scheme = "upi"
        components.host = "pay"
        components.queryItems = items
        return components.url
    }

    static func canPay(fields: [String: String]) -> Bool {
        url(from: fields) != nil
    }

    @MainActor
    static func open(fields: [String: String]) {
        guard let url = url(from: fields) else { return }
        UIApplication.shared.open(url)
        SlipHaptics.shareReady()
    }

    private static func first(_ fields: [String: String], _ keys: [String]) -> String? {
        for k in keys {
            if let v = fields[k]?.trimmingCharacters(in: .whitespacesAndNewlines), !v.isEmpty {
                return v
            }
        }
        return nil
    }
}
