import Foundation
import CryptoKit
import Security

enum VaultCryptoError: Error {
    case keychainFailed(OSStatus)
    case invalidKey
    case encryptionFailed
    case decryptionFailed
    case encodingFailed
}

/// Syncable master key (iCloud Keychain) + AES-256-GCM for pass payloads.
/// Note: synchronizable Keychain items cannot use Secure Enclave; multi-device requires this tradeoff.
enum VaultCrypto {
    private static let mkService = "com.aeswibon.slip.vault"
    private static let mkAccount = "master-key-v1"

    // MARK: - Master key (iCloud Keychain syncable)

    static func masterKey() throws -> SymmetricKey {
        if let existing = try loadMasterKey() {
            return existing
        }
        let key = SymmetricKey(size: .bits256)
        try storeMasterKey(key)
        return key
    }

    private static func loadMasterKey() throws -> SymmetricKey? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: mkService,
            kSecAttrAccount as String: mkAccount,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess, let data = item as? Data else {
            throw VaultCryptoError.keychainFailed(status)
        }
        guard data.count == 32 else { throw VaultCryptoError.invalidKey }
        return SymmetricKey(data: data)
    }

    private static func storeMasterKey(_ key: SymmetricKey) throws {
        let data = key.withUnsafeBytes { Data($0) }
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: mkService,
            kSecAttrAccount as String: mkAccount,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked,
            kSecAttrSynchronizable as String: kCFBooleanTrue as Any,
            kSecValueData as String: data
        ]
        SecItemDelete([
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: mkService,
            kSecAttrAccount as String: mkAccount,
            kSecAttrSynchronizable as String: kCFBooleanTrue as Any
        ] as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw VaultCryptoError.keychainFailed(status)
        }
    }

    // MARK: - Envelope encrypt / decrypt

    struct SealedBox: Codable, Equatable, Sendable {
        var ciphertext: Data
        var nonce: Data
        var wrappedDEK: Data
        var schemaVersion: Int
    }

    static func seal<T: Encodable>(_ value: T, schemaVersion: Int = 1) throws -> SealedBox {
        let mk = try masterKey()
        let dek = SymmetricKey(size: .bits256)
        let plain = try JSONEncoder().encode(value)

        let sealedPayload = try AES.GCM.seal(plain, using: dek)
        guard let combined = sealedPayload.combined else {
            throw VaultCryptoError.encryptionFailed
        }
        // combined = nonce || ciphertext || tag
        let nonce = Data(combined.prefix(12))
        let bodyAndTag = Data(combined.dropFirst(12))

        let dekBytes = dek.withUnsafeBytes { Data($0) }
        let wrapped = try AES.GCM.seal(dekBytes, using: mk)
        guard let wrappedCombined = wrapped.combined else {
            throw VaultCryptoError.encryptionFailed
        }

        return SealedBox(
            ciphertext: bodyAndTag,
            nonce: nonce,
            wrappedDEK: wrappedCombined,
            schemaVersion: schemaVersion
        )
    }

    static func open<T: Decodable>(_ box: SealedBox, as type: T.Type) throws -> T {
        let mk = try masterKey()
        let wrappedBox = try AES.GCM.SealedBox(combined: box.wrappedDEK)
        let dekBytes = try AES.GCM.open(wrappedBox, using: mk)
        guard dekBytes.count == 32 else { throw VaultCryptoError.invalidKey }
        let dek = SymmetricKey(data: dekBytes)

        var combined = Data()
        combined.append(box.nonce)
        combined.append(box.ciphertext)
        let sealed = try AES.GCM.SealedBox(combined: combined)
        let plain = try AES.GCM.open(sealed, using: dek)
        do {
            return try JSONDecoder().decode(T.self, from: plain)
        } catch {
            throw VaultCryptoError.decryptionFailed
        }
    }
}

/// Sensitive pass fields sealed into the vault (never written plaintext to disk).
struct PassVaultPayload: Codable, Equatable, Sendable {
    var templateId: String
    var displayName: String
    var fields: [String: String]
    var stationIds: [String]
    var relevantDateISO8601: String?
    var rationale: String
    var confidence: Double
    var qrPayload: String?
    var barcodeSymbology: String?
    var recognizedText: String?
}
