import CloudKit
import SwiftUI

/// Share a vault pass via iMessage / AirDrop using a `slip://import/…` deep link.
struct PassShareControls: View {
    let package: PassSharePackage

    var body: some View {
        if let url = package.universalLink() ?? package.deepLink() {
            ShareLink(
                item: url,
                subject: Text(package.displayName),
                message: Text("Here's your \(package.displayName) pass for Slip. Tap to open in Slip (App Clip when available).")
            ) {
                Label("Share pass", systemImage: "square.and.arrow.up")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(SlipTheme.ink)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(SlipTheme.cardHigh))
                    .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(Color.white.opacity(0.12), lineWidth: 1))
            }
            .simultaneousGesture(TapGesture().onEnded { SlipHaptics.shareReady() })
        }
    }
}

/// CloudKit Shared Zone on-ramp (family / couple wallet).
struct FamilyVaultShareCard: View {
    @State private var status = "Invite a partner — passes you add sync into a shared CloudKit zone."
    @State private var busy = false
    @State private var shareURL: URL?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Shared family vault")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(SlipTheme.ink)
            Text(status)
                .font(.caption)
                .foregroundStyle(SlipTheme.muted)
            HStack(spacing: 12) {
                Button {
                    Task { await prepareShare() }
                } label: {
                    Text(busy ? "Preparing…" : "Create share link")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(SlipTheme.accent)
                }
                .disabled(busy)

                if let shareURL {
                    ShareLink(item: shareURL, subject: Text("Slip Family Vault"), message: Text("Join my Slip shared wallet.")) {
                        Text("Send invite")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(SlipTheme.ink)
                    }
                }
            }
        }
        .onAppear {
            if let raw = UserDefaults.standard.string(forKey: FamilyVaultShare.shareURLKey),
               let url = URL(string: raw) {
                shareURL = url
                status = "Share ready — send the invite link to your partner."
            }
        }
    }

    private func prepareShare() async {
        busy = true
        defer { busy = false }
        do {
            let url = try await FamilyVaultShare.ensureSharedZone()
            shareURL = url
            status = "Share ready — send the invite link to your partner."
            SlipHaptics.shareReady()
        } catch {
            status = "CloudKit share unavailable: \(error.localizedDescription)"
            SlipHaptics.warning()
        }
    }
}

enum FamilyVaultShare {
    static let zoneName = "FamilyVault"
    static let rootRecordName = "FamilyVaultRoot"
    static let shareURLKey = "slip.family.shareURL"
    static let recordType = "FamilyVaultRoot"

    /// Creates a custom zone + CKShare root so couples can accept via iCloud share URL.
    @MainActor
    static func ensureSharedZone() async throws -> URL {
        let container = CKContainer(identifier: PassVaultStore.cloudContainerId)
        let db = container.privateCloudDatabase
        let zoneID = CKRecordZone.ID(zoneName: zoneName, ownerName: CKCurrentUserDefaultName)
        let zone = CKRecordZone(zoneID: zoneID)
        _ = try await db.save(zone)

        let rootID = CKRecord.ID(recordName: rootRecordName, zoneID: zoneID)
        let root: CKRecord
        do {
            root = try await db.record(for: rootID)
        } catch {
            let created = CKRecord(recordType: recordType, recordID: rootID)
            created["title"] = "Slip Family Vault" as CKRecordValue
            created["schemaVersion"] = 1 as CKRecordValue
            root = try await db.save(created)
        }

        // Reuse existing share if already attached.
        if let existingShare = try await existingShare(for: root, in: db),
           let url = existingShare.url {
            UserDefaults.standard.set(url.absoluteString, forKey: shareURLKey)
            return url
        }

        let share = CKShare(rootRecord: root)
        share[CKShare.SystemFieldKey.title] = "Slip Family Vault" as CKRecordValue
        share.publicPermission = .none

        let (saveResults, _) = try await db.modifyRecords(saving: [root, share], deleting: [])
        var shareURL: URL?
        for (_, result) in saveResults {
            if case .success(let record) = result, let s = record as? CKShare, let url = s.url {
                shareURL = url
            }
        }
        guard let url = shareURL else {
            throw FamilyVaultError.missingShareURL
        }
        UserDefaults.standard.set(url.absoluteString, forKey: shareURLKey)
        return url
    }

    private static func existingShare(for root: CKRecord, in db: CKDatabase) async throws -> CKShare? {
        guard let shareRef = root.share else { return nil }
        return try await db.record(for: shareRef.recordID) as? CKShare
    }

    enum FamilyVaultError: LocalizedError {
        case missingShareURL
        var errorDescription: String? {
            switch self {
            case .missingShareURL: return "CloudKit did not return a share URL."
            }
        }
    }
}
