import Foundation
import CryptoKit

enum BackupError: Error {
    case exportFailed
}

class BackupManager {
    static func export(records: [PassVaultRecord]) throws -> URL {
        let encoder = JSONEncoder()
        let data = try encoder.encode(records.map { $0.sealedBox })
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("VaultBackup.slipvault")
        try data.write(to: url)
        return url
    }
}
