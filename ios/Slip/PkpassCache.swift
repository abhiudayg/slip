import Foundation
import CryptoKit

/// Caches signed .pkpass blobs so Add to Wallet still works offline when fields are unchanged.
enum PkpassCache {
    private static var directory: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = base.appendingPathComponent("PkpassCache", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    static func contentHash(templateId: String, fields: [String: String], serial: String?) -> String {
        let keys = fields.keys.sorted()
        var material = templateId + "|" + (serial ?? "")
        for key in keys {
            material += "|\(key)=\(fields[key] ?? "")"
        }
        let digest = SHA256.hash(data: Data(material.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    static func store(recordId: String, hash: String, data: Data) {
        let url = directory.appendingPathComponent("\(recordId)-\(hash).pkpass")
        // Drop older hashes for this record.
        if let files = try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil) {
            for file in files where file.lastPathComponent.hasPrefix("\(recordId)-") {
                try? FileManager.default.removeItem(at: file)
            }
        }
        try? data.write(to: url, options: .atomic)
        // Also mirror last-known into App Group for Watch handoff diagnostics.
        if let defaults = UserDefaults(suiteName: "group.com.aeswibon.slip") {
            defaults.set(hash, forKey: "slip.pkpass.hash.\(recordId)")
            defaults.set(Date().timeIntervalSince1970, forKey: "slip.pkpass.cachedAt.\(recordId)")
        }
    }

    static func load(recordId: String, hash: String) -> Data? {
        let url = directory.appendingPathComponent("\(recordId)-\(hash).pkpass")
        return try? Data(contentsOf: url)
    }
}
