import AuthenticationServices
import Security
import SwiftUI
import UIKit

// MARK: - Keychain helper for sensitive auth fields

private enum SecureStore {
    private static let service = "com.aeswibon.slip.auth"

    static func set(_ value: String, forKey account: String) {
        let data = Data(value.utf8)
        // Delete any pre-existing item (both sync scopes) before writing.
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecAttrSynchronizable as String: kSecAttrSynchronizableAny
        ]
        SecItemDelete(deleteQuery as CFDictionary)

        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked,
            kSecAttrSynchronizable as String: kCFBooleanFalse as Any,
            kSecValueData as String: data
        ]
        SecItemAdd(addQuery as CFDictionary, nil)
    }

    static func get(forKey account: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecAttrSynchronizable as String: kSecAttrSynchronizableAny,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess, let data = item as? Data else { return nil }
        let value = String(data: data, encoding: .utf8)
        return value?.isEmpty == true ? nil : value
    }

    static func remove(forKey account: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecAttrSynchronizable as String: kSecAttrSynchronizableAny
        ]
        SecItemDelete(query as CFDictionary)
    }
}

/// Session gate — Sign in with Apple before the vault UI. Cloud API status is probed here.
@MainActor
final class AuthSession: ObservableObject {
    private enum Keys {
        /// Sensitive fields stored in Keychain via SecureStore.
        static let userID = "slip.auth.userID"
        static let email = "slip.auth.email"
        /// Non-sensitive fields remain in UserDefaults.
        static let displayName = "slip.auth.displayName"
        static let avatarJPEG = "slip.auth.avatarJPEG"
    }

    private let defaults = UserDefaults.standard

    @Published private(set) var userID: String = ""
    @Published private(set) var displayName: String = ""
    @Published private(set) var email: String = ""
    @Published private(set) var avatarImage: UIImage?
    @Published var cloudStatus: CloudStatus = .checking
    @Published var lastError: String?

    enum CloudStatus: Equatable {
        case checking
        case connected(brandCount: Int)
        case unreachable(String)

        var isReady: Bool {
            if case .connected = self { return true }
            return false
        }
    }

    var isSignedIn: Bool { !userID.isEmpty }

    /// True when Apple did not supply a usable name (common on re-auth).
    var needsDisplayName: Bool {
        let name = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        return name.isEmpty || name == "Slip user"
    }

    var monogram: String {
        let name = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        let source: String
        if !name.isEmpty, name != "Slip user" {
            source = name
        } else if let local = email.split(separator: "@").first, !local.isEmpty {
            source = String(local)
        } else {
            source = "S"
        }
        let parts = source.split(whereSeparator: { $0.isWhitespace }).prefix(2)
        let letters = parts.compactMap { $0.first.map(String.init) }
        return (letters.isEmpty ? ["S"] : letters).joined().uppercased()
    }

    init() {
        // Migration: move legacy plaintext UserDefaults → Keychain on first launch.
        migrateToKeychainIfNeeded()

        userID = SecureStore.get(forKey: Keys.userID) ?? ""
        displayName = defaults.string(forKey: Keys.displayName) ?? ""
        email = SecureStore.get(forKey: Keys.email) ?? ""
        if let data = defaults.data(forKey: Keys.avatarJPEG), !data.isEmpty {
            avatarImage = UIImage(data: data)
        }
    }

    /// One-time migration from plaintext UserDefaults to Keychain for sensitive fields.
    private func migrateToKeychainIfNeeded() {
        if SecureStore.get(forKey: Keys.userID) == nil,
           let legacyID = defaults.string(forKey: Keys.userID),
           !legacyID.isEmpty {
            SecureStore.set(legacyID, forKey: Keys.userID)
            defaults.removeObject(forKey: Keys.userID)
        }
        if SecureStore.get(forKey: Keys.email) == nil,
           let legacyEmail = defaults.string(forKey: Keys.email),
           !legacyEmail.isEmpty {
            SecureStore.set(legacyEmail, forKey: Keys.email)
            defaults.removeObject(forKey: Keys.email)
        }
    }

    /// Confirms the stored Apple user is still authorized; signs out if revoked.
    func validatePersistedAppleSession() async {
        let stored = SecureStore.get(forKey: Keys.userID) ?? ""
        guard !stored.isEmpty else {
            if !userID.isEmpty { signOut() }
            return
        }
        // Simulator / DEBUG local sessions are not Apple credentials.
        if stored.hasPrefix("simulator.slip.") {
            restoreLocalSession(userID: stored)
            return
        }
        let provider = ASAuthorizationAppleIDProvider()
        do {
            let state = try await provider.credentialState(forUserID: stored)
            switch state {
            case .authorized, .transferred:
                restoreLocalSession(userID: stored)
            case .revoked, .notFound:
                signOut()
            @unknown default:
                restoreLocalSession(userID: stored)
            }
        } catch {
            restoreLocalSession(userID: stored)
        }
    }

    func refreshCloud(using api: PassAPIClient) async {
        cloudStatus = .checking
        lastError = nil
        do {
            let health = try await api.fetchHealth()
            guard health.status == "ok" else {
                cloudStatus = .unreachable("Cloud reported \(health.status)")
                return
            }
            let brands = try await api.fetchBrands()
            cloudStatus = .connected(brandCount: brands.count)
        } catch {
            cloudStatus = .unreachable(error.localizedDescription)
            lastError = error.localizedDescription
        }
    }

    /// Local-only session for Simulator / DEBUG builds (no Apple ID required).
    func signInForSimulatorTesting(
        displayName: String = "Alex",
        email: String = "alex@slip.local"
    ) {
        let id = "simulator.slip.\(UUID().uuidString)"
        userID = id
        SecureStore.set(id, forKey: Keys.userID)
        self.displayName = displayName
        defaults.set(displayName, forKey: Keys.displayName)
        self.email = email
        SecureStore.set(email, forKey: Keys.email)
    }

    func applyAppleCredential(userID: String, fullName: PersonNameComponents?, email: String?) {
        self.userID = userID
        SecureStore.set(userID, forKey: Keys.userID)

        if let email {
            let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                self.email = trimmed
                SecureStore.set(trimmed, forKey: Keys.email)
            }
        }

        // Apple only includes fullName on the *first* successful authorization for an app.
        if let resolved = Self.resolvedName(from: fullName) {
            displayName = resolved
            defaults.set(resolved, forKey: Keys.displayName)
        } else if needsDisplayName {
            let stored = defaults.string(forKey: Keys.displayName)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if !stored.isEmpty, stored != "Slip user" {
                displayName = stored
            } else if let local = self.email.split(separator: "@").first, local.count >= 2 {
                displayName = String(local)
                defaults.set(displayName, forKey: Keys.displayName)
            } else {
                displayName = ""
                defaults.removeObject(forKey: Keys.displayName)
            }
        }
        // Profile photo is never provided by Sign in with Apple — user picks one in Settings.
    }

    func updateDisplayName(_ name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        displayName = trimmed
        if trimmed.isEmpty {
            defaults.removeObject(forKey: Keys.displayName)
        } else {
            defaults.set(trimmed, forKey: Keys.displayName)
        }
    }

    func updateAvatar(_ image: UIImage?) {
        guard let image else {
            defaults.removeObject(forKey: Keys.avatarJPEG)
            avatarImage = nil
            return
        }
        let target = CGSize(width: 256, height: 256)
        let prepared = image.preparingThumbnail(of: target) ?? image
        let data = prepared.jpegData(compressionQuality: 0.82) ?? Data()
        defaults.set(data, forKey: Keys.avatarJPEG)
        avatarImage = UIImage(data: data) ?? prepared
    }

    func signOut() {
        userID = ""
        displayName = ""
        email = ""
        SecureStore.remove(forKey: Keys.userID)
        defaults.removeObject(forKey: Keys.displayName)
        SecureStore.remove(forKey: Keys.email)
        updateAvatar(nil)
    }

    private func restoreLocalSession(userID: String) {
        self.userID = userID
        displayName = defaults.string(forKey: Keys.displayName) ?? ""
        email = SecureStore.get(forKey: Keys.email) ?? ""
        if let data = defaults.data(forKey: Keys.avatarJPEG), !data.isEmpty {
            avatarImage = UIImage(data: data)
        }
    }

    private static func resolvedName(from components: PersonNameComponents?) -> String? {
        guard let components else { return nil }
        var parts: [String] = []
        if let given = components.givenName?.trimmingCharacters(in: .whitespacesAndNewlines), !given.isEmpty {
            parts.append(given)
        }
        if let family = components.familyName?.trimmingCharacters(in: .whitespacesAndNewlines), !family.isEmpty {
            parts.append(family)
        }
        if !parts.isEmpty {
            return parts.joined(separator: " ")
        }
        let formatted = PersonNameComponentsFormatter()
            .string(from: components)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return formatted.isEmpty ? nil : formatted
    }
}
