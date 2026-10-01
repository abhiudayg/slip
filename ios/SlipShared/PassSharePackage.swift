import Foundation

/// Compact transferable pass for iMessage / AirDrop / Universal Links (`slip://import/...`).
struct PassSharePackage: Codable, Equatable, Sendable {
    var v: Int = 1
    var templateId: String
    var displayName: String
    var fields: [String: String]
    var qrPayload: String?
    var relevantDateISO8601: String?
    var stationIds: [String] = []

    static func from(payload: PassVaultPayload) -> PassSharePackage {
        // Keep share payload lean — drop geofence coords / long OCR dumps.
        let drop: Set<String> = ["recognized_text", "latitude", "longitude", "note"]
        let trimmed = payload.fields.filter { !drop.contains($0.key) && !$0.value.isEmpty }
        return PassSharePackage(
            templateId: payload.templateId,
            displayName: payload.displayName,
            fields: trimmed,
            qrPayload: payload.qrPayload ?? trimmed["qr_data"],
            relevantDateISO8601: payload.relevantDateISO8601,
            stationIds: payload.stationIds
        )
    }

    static func from(classification: ClassificationResult) -> PassSharePackage {
        PassSharePackage(
            templateId: classification.templateId,
            displayName: classification.displayName,
            fields: classification.fields,
            qrPayload: classification.fields["qr_data"] ?? classification.extracted.qrPayload,
            relevantDateISO8601: classification.relevantDateISO8601,
            stationIds: classification.stationIds
        )
    }

    func encodeToken() -> String? {
        guard let data = try? JSONEncoder().encode(self) else { return nil }
        return data.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    static func decodeToken(_ token: String) -> PassSharePackage? {
        var b64 = token
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        while b64.count % 4 != 0 { b64.append("=") }
        guard let data = Data(base64Encoded: b64),
              let pkg = try? JSONDecoder().decode(PassSharePackage.self, from: data) else { return nil }
        return pkg
    }

    func deepLink() -> URL? {
        guard let token = encodeToken() else { return nil }
        return URL(string: "slip://import/\(token)")
    }

    func asClassification() -> ClassificationResult {
        var fields = self.fields
        if let qr = qrPayload?.trimmingCharacters(in: .whitespacesAndNewlines), !qr.isEmpty {
            fields["qr_data"] = qr
        }
        let ticket = ExtractedTicket(
            qrPayload: qrPayload,
            barcodeSymbology: qrPayload == nil ? nil : "qr",
            recognizedText: displayName,
            tokens: [],
            createdAt: Date()
        )
        return ClassificationResult(
            templateId: templateId,
            displayName: displayName,
            confidence: 0.94,
            fields: fields,
            stationIds: stationIds,
            relevantDateISO8601: relevantDateISO8601,
            rationale: "Imported via Slip share link",
            needsManualBrandPick: templateId.isEmpty,
            extracted: ticket,
            createdAt: Date()
        )
    }

    static func parse(from url: URL) -> PassSharePackage? {
        guard url.scheme == "slip" else { return nil }
        let parts = url.pathComponents.filter { $0 != "/" }
        if url.host == "import" || url.host == "share" {
            if let token = parts.first { return decodeToken(token) }
        }
        if let head = parts.first, (head == "import" || head == "share"), let token = parts.dropFirst().first {
            return decodeToken(token)
        }
        return nil
    }
}
