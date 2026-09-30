import Foundation
import SwiftData
import LocalAuthentication
import CloudKit

@Model
final class PassVaultRecord {
    @Attribute(.unique) var id: String
    var templateId: String
    var displayName: String
    var createdAt: Date
    var updatedAt: Date
    var walletAdded: Bool
    var schemaVersion: Int
    var ciphertext: Data
    var nonce: Data
    var wrappedDEK: Data
    var cloudKitRecordName: String?

    init(
        id: String = UUID().uuidString,
        templateId: String,
        displayName: String,
        sealed: VaultCrypto.SealedBox,
        walletAdded: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.templateId = templateId
        self.displayName = displayName
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.walletAdded = walletAdded
        self.schemaVersion = sealed.schemaVersion
        self.ciphertext = sealed.ciphertext
        self.nonce = sealed.nonce
        self.wrappedDEK = sealed.wrappedDEK
        self.cloudKitRecordName = id
    }

    var sealedBox: VaultCrypto.SealedBox {
        VaultCrypto.SealedBox(
            ciphertext: ciphertext,
            nonce: nonce,
            wrappedDEK: wrappedDEK,
            schemaVersion: schemaVersion
        )
    }
}

@MainActor
final class PassVaultStore: ObservableObject {
    static let cloudContainerId = "iCloud.com.aeswibon.slip"
    static let recordType = "EncryptedPass"

    @Published private(set) var records: [PassVaultRecord] = []
    @Published private(set) var isUnlocked = false
    @Published var lastError: String?

    private let container: ModelContainer
    private let context: ModelContext
    private let cloudDB: CKDatabase

    init(inMemory: Bool = false) {
        let schema = Schema([PassVaultRecord.self])
        let config = ModelConfiguration(
            "SlipPassVault",
            schema: schema,
            isStoredInMemoryOnly: inMemory,
            cloudKitDatabase: .none // encrypt-before-write; custom CK sync
        )
        do {
            container = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("PassVaultStore container failed: \(error)")
        }
        context = ModelContext(container)
        cloudDB = CKContainer(identifier: Self.cloudContainerId).privateCloudDatabase
        refresh()
    }

    func refresh() {
        let descriptor = FetchDescriptor<PassVaultRecord>(
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        records = (try? context.fetch(descriptor)) ?? []
    }

    // MARK: - Biometrics

    func unlock(reason: String = "Unlock Slip vault to view pass details") async -> Bool {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            // Simulator / no biometrics: allow with device passcode unavailable → unlock for dev
            isUnlocked = true
            return true
        }
        do {
            let ok = try await context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: reason
            )
            isUnlocked = ok
            return ok
        } catch {
            lastError = error.localizedDescription
            isUnlocked = false
            return false
        }
    }

    func lock() {
        isUnlocked = false
    }

    // MARK: - CRUD

    @discardableResult
    func save(from classification: ClassificationResult, walletAdded: Bool = false) throws -> PassVaultRecord {
        let payload = PassVaultPayload(
            templateId: classification.templateId,
            displayName: classification.displayName,
            fields: classification.fields,
            stationIds: classification.stationIds,
            relevantDateISO8601: classification.relevantDateISO8601,
            rationale: classification.rationale,
            confidence: classification.confidence,
            qrPayload: classification.extracted.qrPayload,
            barcodeSymbology: classification.extracted.barcodeSymbology,
            recognizedText: classification.extracted.recognizedText
        )
        return try save(payload: payload, walletAdded: walletAdded)
    }

    @discardableResult
    func save(payload: PassVaultPayload, walletAdded: Bool = false) throws -> PassVaultRecord {
        let sealed = try VaultCrypto.seal(payload)
        let record = PassVaultRecord(
            templateId: payload.templateId,
            displayName: payload.displayName.isEmpty ? payload.templateId : payload.displayName,
            sealed: sealed,
            walletAdded: walletAdded
        )
        context.insert(record)
        try context.save()
        refresh()
        Task { await pushToCloud(record) }
        return record
    }

    func decrypt(_ record: PassVaultRecord) throws -> PassVaultPayload {
        try VaultCrypto.open(record.sealedBox, as: PassVaultPayload.self)
    }

    func markWalletAdded(_ record: PassVaultRecord) throws {
        record.walletAdded = true
        record.updatedAt = Date()
        try context.save()
        refresh()
        Task { await pushToCloud(record) }
    }

    func delete(_ record: PassVaultRecord) throws {
        let name = record.cloudKitRecordName ?? record.id
        context.delete(record)
        try context.save()
        refresh()
        Task { await deleteFromCloud(recordName: name) }
    }

    // MARK: - CloudKit sync (ciphertext only)

    func syncFromCloud() async {
        let query = CKQuery(recordType: Self.recordType, predicate: NSPredicate(value: true))
        do {
            let (results, _) = try await cloudDB.records(matching: query)
            for (_, result) in results {
                guard case .success(let ck) = result else { continue }
                try upsertFromCloud(ck)
            }
            try context.save()
            refresh()
        } catch {
            // CloudKit may be unavailable until entitlements/container exist — non-fatal
            lastError = error.localizedDescription
        }
    }

    private func pushToCloud(_ record: PassVaultRecord) async {
        let ck = CKRecord(recordType: Self.recordType, recordID: CKRecord.ID(recordName: record.id))
        ck["templateId"] = record.templateId as CKRecordValue
        ck["displayName"] = record.displayName as CKRecordValue
        ck["createdAt"] = record.createdAt as CKRecordValue
        ck["updatedAt"] = record.updatedAt as CKRecordValue
        ck["walletAdded"] = (record.walletAdded ? 1 : 0) as CKRecordValue
        ck["schemaVersion"] = record.schemaVersion as CKRecordValue
        ck["ciphertext"] = record.ciphertext as CKRecordValue
        ck["nonce"] = record.nonce as CKRecordValue
        ck["wrappedDEK"] = record.wrappedDEK as CKRecordValue
        do {
            _ = try await cloudDB.save(ck)
        } catch {
            lastError = error.localizedDescription
        }
    }

    private func deleteFromCloud(recordName: String) async {
        do {
            try await cloudDB.deleteRecord(withID: CKRecord.ID(recordName: recordName))
        } catch {
            lastError = error.localizedDescription
        }
    }

    private func upsertFromCloud(_ ck: CKRecord) throws {
        let id = ck.recordID.recordName
        let descriptor = FetchDescriptor<PassVaultRecord>(
            predicate: #Predicate { $0.id == id }
        )
        let existing = try context.fetch(descriptor).first
        let remoteUpdated = (ck["updatedAt"] as? Date) ?? .distantPast

        if let existing, existing.updatedAt >= remoteUpdated {
            return
        }

        guard
            let ciphertext = ck["ciphertext"] as? Data,
            let nonce = ck["nonce"] as? Data,
            let wrappedDEK = ck["wrappedDEK"] as? Data,
            let templateId = ck["templateId"] as? String
        else { return }

        let sealed = VaultCrypto.SealedBox(
            ciphertext: ciphertext,
            nonce: nonce,
            wrappedDEK: wrappedDEK,
            schemaVersion: (ck["schemaVersion"] as? Int) ?? 1
        )

        if let existing {
            existing.templateId = templateId
            existing.displayName = (ck["displayName"] as? String) ?? templateId
            existing.updatedAt = remoteUpdated
            existing.walletAdded = ((ck["walletAdded"] as? Int) ?? 0) != 0
            existing.schemaVersion = sealed.schemaVersion
            existing.ciphertext = sealed.ciphertext
            existing.nonce = sealed.nonce
            existing.wrappedDEK = sealed.wrappedDEK
        } else {
            let record = PassVaultRecord(
                id: id,
                templateId: templateId,
                displayName: (ck["displayName"] as? String) ?? templateId,
                sealed: sealed,
                walletAdded: ((ck["walletAdded"] as? Int) ?? 0) != 0,
                createdAt: (ck["createdAt"] as? Date) ?? remoteUpdated,
                updatedAt: remoteUpdated
            )
            context.insert(record)
        }
    }
}
