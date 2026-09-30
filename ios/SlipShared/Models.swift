import Foundation

/// On-device extraction result from a shared screenshot or camera frame.
struct ExtractedTicket: Codable, Equatable, Sendable {
    var qrPayload: String?
    var barcodeSymbology: String?
    var recognizedText: String
    var tokens: [String]
    var createdAt: Date

    var haystack: String {
        let parts = [qrPayload, recognizedText].compactMap { $0 }
        return parts.joined(separator: "\n").lowercased()
    }
}

/// Local classifier output — template pick + prefilled fields.
struct ClassificationResult: Codable, Equatable, Identifiable, Sendable {
    var id: String { "\(templateId)-\(createdAt.timeIntervalSince1970)" }
    var templateId: String
    var displayName: String
    var confidence: Double
    var fields: [String: String]
    var stationIds: [String]
    var relevantDateISO8601: String?
    var rationale: String
    var needsManualBrandPick: Bool
    var extracted: ExtractedTicket
    var createdAt: Date

    static let storageKey = "slip.pending.classification"
}

enum SharedInbox {
    static let appGroupId = "group.com.aeswibon.slip"

    /// One-shot share handoff only — never long-lived plaintext storage.
    /// Caller must consume promptly; data is deleted on read.
    static func save(_ result: ClassificationResult) {
        guard let defaults = UserDefaults(suiteName: appGroupId),
              let data = try? JSONEncoder().encode(result) else { return }
        defaults.set(data, forKey: ClassificationResult.storageKey)
        // Clear legacy barcode-only key
        defaults.removeObject(forKey: "slip.pending.barcode")
    }

    static func consumeClassification() -> ClassificationResult? {
        guard let defaults = UserDefaults(suiteName: appGroupId),
              let data = defaults.data(forKey: ClassificationResult.storageKey) else { return nil }
        defaults.removeObject(forKey: ClassificationResult.storageKey)
        return try? JSONDecoder().decode(ClassificationResult.self, from: data)
    }

    static func wipeAll() {
        guard let defaults = UserDefaults(suiteName: appGroupId) else { return }
        defaults.removeObject(forKey: ClassificationResult.storageKey)
        defaults.removeObject(forKey: "slip.pending.barcode")
    }
}
