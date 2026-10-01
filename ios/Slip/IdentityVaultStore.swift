import Foundation
import Combine

enum IdentityKind: String, Codable, CaseIterable, Identifiable {
    case aadhaar
    case pan
    case drivingLicense
    case other

    var id: String { rawValue }

    var title: String {
        switch self {
        case .aadhaar: return "Aadhaar"
        case .pan: return "PAN"
        case .drivingLicense: return "Driving Licence"
        case .other: return "ID"
        }
    }

    var systemImage: String {
        switch self {
        case .aadhaar: return "person.text.rectangle"
        case .pan: return "creditcard"
        case .drivingLicense: return "car.fill"
        case .other: return "person.crop.rectangle"
        }
    }
}

struct IdentityDocument: Codable, Identifiable, Equatable, Sendable {
    var id: String
    var kind: IdentityKind
    var displayName: String
    /// Masked / short fields only — never store full Aadhaar in plaintext labels.
    var fields: [String: String]
    var createdAt: Date
    var updatedAt: Date
}

/// Local encrypted ID cards (DigiLocker-style vault). Full DigiLocker OAuth is gated behind ASC / UIDAI approval.
@MainActor
final class IdentityVaultStore: ObservableObject {
    static let shared = IdentityVaultStore()

    @Published private(set) var documents: [IdentityDocument] = []

    private let defaultsKey = "slip.identity.docs.v1"
    private let suite = UserDefaults(suiteName: SharedInbox.appGroupId) ?? .standard

    init() {
        reload()
    }

    func reload() {
        guard let data = suite.data(forKey: defaultsKey),
              let box = try? JSONDecoder().decode(VaultCrypto.SealedBox.self, from: data),
              let docs = try? VaultCrypto.open(box, as: [IdentityDocument].self) else {
            documents = []
            return
        }
        documents = docs.sorted { $0.updatedAt > $1.updatedAt }
    }

    func upsert(_ doc: IdentityDocument) throws {
        var next = documents.filter { $0.id != doc.id }
        next.append(doc)
        try persist(next)
    }

    func delete(id: String) throws {
        try persist(documents.filter { $0.id != id })
    }

    func preferredForTravel() -> IdentityDocument? {
        documents.first(where: { $0.kind == .aadhaar })
            ?? documents.first(where: { $0.kind == .drivingLicense })
            ?? documents.first
    }

    private func persist(_ docs: [IdentityDocument]) throws {
        let sealed = try VaultCrypto.seal(docs)
        let data = try JSONEncoder().encode(sealed)
        suite.set(data, forKey: defaultsKey)
        documents = docs.sorted { $0.updatedAt > $1.updatedAt }
    }
}
