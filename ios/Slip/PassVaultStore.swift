import Foundation
import SwiftData
import LocalAuthentication
import CloudKit
import PassKit

@Model
final class PassVaultRecord {
    @Attribute(.unique) var id: String
    var templateId: String
    var displayName: String
    var createdAt: Date
    var updatedAt: Date
    var walletAdded: Bool
    /// When set and now >= expiresAt, the pass is shown under Expired.
    var expiresAt: Date?
    /// PassKit serial used to detect removal from Apple Wallet.
    var walletSerialNumber: String?
    var walletPassTypeIdentifier: String?
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
        expiresAt: Date? = nil,
        walletSerialNumber: String? = nil,
        walletPassTypeIdentifier: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.templateId = templateId
        self.displayName = displayName
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.walletAdded = walletAdded
        self.expiresAt = expiresAt
        self.walletSerialNumber = walletSerialNumber
        self.walletPassTypeIdentifier = walletPassTypeIdentifier
        self.schemaVersion = sealed.schemaVersion
        self.ciphertext = sealed.ciphertext
        self.nonce = sealed.nonce
        self.wrappedDEK = sealed.wrappedDEK
        self.cloudKitRecordName = id
    }

    var isExpired: Bool {
        PassExpiration.isExpired(expiresAt)
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
        let relevant = PassExpiration.relevantDateISO8601(
            templateId: classification.templateId,
            fields: classification.fields,
            existing: classification.relevantDateISO8601
        )
        let payload = PassVaultPayload(
            templateId: classification.templateId,
            displayName: classification.displayName,
            fields: classification.fields,
            stationIds: classification.stationIds,
            relevantDateISO8601: relevant,
            rationale: classification.rationale,
            confidence: classification.confidence,
            qrPayload: classification.extracted.qrPayload,
            barcodeSymbology: classification.extracted.barcodeSymbology,
            recognizedText: classification.extracted.recognizedText
        )
        return try save(payload: payload, walletAdded: walletAdded)
    }

    @discardableResult
    func save(
        payload: PassVaultPayload,
        walletAdded: Bool = false,
        walletPass: PKPass? = nil
    ) throws -> PassVaultRecord {
        let sealed = try VaultCrypto.seal(payload)
        let expires = PassExpiration.expiresAt(
            templateId: payload.templateId,
            fields: payload.fields,
            relevantDateISO8601: payload.relevantDateISO8601
        )
        let record = PassVaultRecord(
            templateId: payload.templateId,
            displayName: payload.displayName.isEmpty ? payload.templateId : payload.displayName,
            sealed: sealed,
            walletAdded: walletAdded,
            expiresAt: expires,
            walletSerialNumber: walletPass?.serialNumber,
            walletPassTypeIdentifier: walletPass?.passTypeIdentifier
        )
        context.insert(record)
        try context.save()
        refresh()
        Task { await pushToCloud(record) }
        return record
    }

    /// Replace sealed payload on an existing vault row (regenerate / edit) without creating a duplicate.
    @discardableResult
    func update(
        _ record: PassVaultRecord,
        payload: PassVaultPayload,
        walletAdded: Bool? = nil,
        walletPass: PKPass? = nil
    ) throws -> PassVaultRecord {
        let sealed = try VaultCrypto.seal(payload)
        let expires = PassExpiration.expiresAt(
            templateId: payload.templateId,
            fields: payload.fields,
            relevantDateISO8601: payload.relevantDateISO8601
        )
        record.templateId = payload.templateId
        record.displayName = payload.displayName.isEmpty ? payload.templateId : payload.displayName
        record.schemaVersion = sealed.schemaVersion
        record.ciphertext = sealed.ciphertext
        record.nonce = sealed.nonce
        record.wrappedDEK = sealed.wrappedDEK
        record.expiresAt = expires
        record.updatedAt = Date()
        if let walletPass {
            let newSerial = walletPass.serialNumber
            let installed = PKPassLibrary().containsPass(walletPass)
            let hadSerial = !(record.walletSerialNumber?
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? "").isEmpty
            // Only replace serial when empty or the new pass is already in Wallet.
            // Overwriting with a fresh unused serial clears the badge and causes duplicates.
            if !hadSerial || installed {
                record.walletSerialNumber = newSerial
                record.walletPassTypeIdentifier = walletPass.passTypeIdentifier
            }
            if installed {
                record.walletAdded = true
            } else if WalletPassLink.isInstalled(
                serial: record.walletSerialNumber,
                passTypeIdentifier: record.walletPassTypeIdentifier
            ) {
                record.walletAdded = true
            } else if let walletAdded {
                record.walletAdded = walletAdded
            }
        } else if let walletAdded {
            record.walletAdded = walletAdded
        }
        try context.save()
        refresh()
        Task { await pushToCloud(record) }
        return record
    }

    func decrypt(_ record: PassVaultRecord) throws -> PassVaultPayload {
        try VaultCrypto.open(record.sealedBox, as: PassVaultPayload.self)
    }

    func markWalletAdded(_ record: PassVaultRecord, pass: PKPass? = nil) throws {
        record.walletAdded = true
        if let pass {
            record.walletSerialNumber = pass.serialNumber
            record.walletPassTypeIdentifier = pass.passTypeIdentifier
        }
        record.updatedAt = Date()
        try context.save()
        refresh()
        Task { await pushToCloud(record) }
    }

    func clearWalletAdded(_ record: PassVaultRecord) throws {
        guard record.walletAdded else { return }
        record.walletAdded = false
        record.updatedAt = Date()
        try context.save()
        refresh()
        Task { await pushToCloud(record) }
    }

    /// Reconcile `walletAdded` with PassKit (clears badge when user deletes the pass from Wallet).
    @discardableResult
    func syncWalletPresence() -> Int {
        let library = PKPassLibrary()
        var changed = 0

        for record in records {
            var serial = record.walletSerialNumber?
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

            // Reclaim a unique Wallet pass for this brand when serial was lost/overwritten.
            if serial.isEmpty || !WalletPassLink.isInstalled(
                serial: serial,
                passTypeIdentifier: record.walletPassTypeIdentifier,
                library: library
            ) {
                let matches = WalletPassLink.candidateLibraryPasses(
                    for: record,
                    vaultRecords: records,
                    organizationName: WalletPassLink.organizationName(forTemplateId: record.templateId),
                    library: library
                )
                if matches.count == 1, let only = matches.first {
                    record.walletSerialNumber = only.serialNumber
                    record.walletPassTypeIdentifier = only.passTypeIdentifier
                    serial = only.serialNumber
                    changed += 1
                }
            }

            guard !serial.isEmpty else { continue }

            let present = WalletPassLink.isInstalled(
                serial: serial,
                passTypeIdentifier: record.walletPassTypeIdentifier,
                library: library
            )

            if record.walletAdded != present {
                record.walletAdded = present
                record.updatedAt = Date()
                changed += 1
                Task { await pushToCloud(record) }
            }
        }

        if changed > 0 {
            try? context.save()
            refresh()
        }
        return changed
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
        if let expiresAt = record.expiresAt {
            ck["expiresAt"] = expiresAt as CKRecordValue
        }
        if let serial = record.walletSerialNumber {
            ck["walletSerialNumber"] = serial as CKRecordValue
        }
        if let passType = record.walletPassTypeIdentifier {
            ck["walletPassTypeIdentifier"] = passType as CKRecordValue
        }
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
            existing.expiresAt = ck["expiresAt"] as? Date
            existing.walletSerialNumber = ck["walletSerialNumber"] as? String
            existing.walletPassTypeIdentifier = ck["walletPassTypeIdentifier"] as? String
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
                expiresAt: ck["expiresAt"] as? Date,
                walletSerialNumber: ck["walletSerialNumber"] as? String,
                walletPassTypeIdentifier: ck["walletPassTypeIdentifier"] as? String,
                createdAt: (ck["createdAt"] as? Date) ?? remoteUpdated,
                updatedAt: remoteUpdated
            )
            context.insert(record)
        }
    }
}
