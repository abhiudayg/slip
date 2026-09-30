import Foundation

struct UPIPassHandler: BrandPassHandler {
    let templateId = "upi"
    let priority = 10

    func matches(qr: String, hay: String, ticket: ExtractedTicket) -> Bool { true }

    func classify(qr: String, hay: String, ticket: ExtractedTicket) -> ClassificationResult? {
        UPIPassLogic.classify(qr: qr, hay: hay, ticket: ticket)
    }

    func enrich(_ result: ClassificationResult) -> ClassificationResult {
        var result = result
        let qr = result.fields["qr_data"]?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if result.fields["vpa"]?.isEmpty != false, let vpa = TicketText.upiQueryValue(qr, key: "pa") {
            result.fields["vpa"] = vpa
        }
        if result.fields["name"]?.isEmpty != false, let pn = TicketText.upiQueryValue(qr, key: "pn") {
            result.fields["name"] = pn.replacingOccurrences(of: "+", with: " ")
        }
        let dn = result.displayName.lowercased()
        if (dn == "upi" || dn == "upi get paid" || dn == "upi paypass"),
           let name = result.fields["name"], !name.isEmpty {
            result.displayName = name
        }
        return result
    }
}

enum UPIPassLogic {
    static func classify(qr: String, hay: String, ticket: ExtractedTicket) -> ClassificationResult? {
        let isUPI = qr.lowercased().hasPrefix("upi://")
            || hay.contains("upi://pay")
            || (hay.contains("upi") && (hay.contains("scan") || hay.contains("pay")))
        guard isUPI else { return nil }

        let payload = qr.isEmpty ? (ticket.qrPayload ?? "") : qr
        var fields: [String: String] = [
            "qr_data": payload,
            "name": "",
            "vpa": "",
            "bank": ""
        ]
        if let vpa = TicketText.upiQueryValue(payload, key: "pa") {
            fields["vpa"] = vpa
        }
        if let name = TicketText.upiQueryValue(payload, key: "pn") {
            fields["name"] = name.replacingOccurrences(of: "+", with: " ")
        } else if let named = TicketText.firstMatch(in: ticket.recognizedText, pattern: #"(?i)(?:name|payee|account holder)\s*[:\-]?\s*([A-Za-z][A-Za-z .]{2,})"#) {
            fields["name"] = named
        }
        if let bank = TicketText.firstMatch(in: ticket.recognizedText, pattern: #"(?i)((?:ICICI|HDFC|SBI|Axis|Kotak|Yes|IDFC|Federal|BOB|PNB|Canara)\s*Bank)"#) {
            fields["bank"] = bank
        }

        return TicketText.result(
            templateId: "upi",
            displayName: (fields["name"]?.isEmpty == false) ? fields["name"]! : "UPI PayPass",
            confidence: payload.lowercased().hasPrefix("upi://") ? 0.98 : 0.75,
            fields: fields,
            rationale: "Detected UPI PayPass QR",
            ticket: ticket
        )
    }


}
