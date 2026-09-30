import Foundation
import PassKit

/// Resolves / preserves PassKit identity so regenerate updates in place instead of duplicating.
enum WalletPassLink {
    /// Matches `organizationName` in templates/*/pass.json (PassKit identity).
    static func organizationName(forTemplateId templateId: String) -> String {
        switch templateId {
        case "airbnb": return "Airbnb"
        case "bookmyshow": return "BookMyShow"
        case "district": return "District"
        case "irctc": return "IRCTC"
        case "indigo": return "IndiGo"
        case "namma-metro": return "Namma Metro"
        case "redbus": return "redBus"
        case "zoomcar": return "Zoomcar"
        case "upi": return "UPI"
        case "easydiner": return "EazyDiner"
        case "zomato-dineout": return "Zomato"
        case "swiggy-dineout": return "Swiggy"
        default: return templateId
        }
    }

    static func libraryPass(
        serial: String?,
        passTypeIdentifier: String? = nil,
        library: PKPassLibrary = PKPassLibrary()
    ) -> PKPass? {
        let trimmed = serial?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !trimmed.isEmpty else { return nil }
        return library.passes().first { pass in
            pass.serialNumber == trimmed
                && (passTypeIdentifier == nil
                    || passTypeIdentifier?.isEmpty == true
                    || pass.passTypeIdentifier == passTypeIdentifier)
        }
    }

    static func isInstalled(
        serial: String?,
        passTypeIdentifier: String? = nil,
        library: PKPassLibrary = PKPassLibrary()
    ) -> Bool {
        libraryPass(serial: serial, passTypeIdentifier: passTypeIdentifier, library: library) != nil
    }

    /// Prefer a serial that already exists in Apple Wallet for this vault row.
    /// - Parameter organizationName: PassKit `organizationName` (e.g. "Airbnb") — required for
    ///   recovery because Slip brands share one passTypeIdentifier.
    static func serialForRegenerate(
        record: PassVaultRecord,
        vaultRecords: [PassVaultRecord],
        organizationName: String?,
        library: PKPassLibrary = PKPassLibrary()
    ) -> String {
        let stored = record.walletSerialNumber?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        if !stored.isEmpty,
           isInstalled(serial: stored, passTypeIdentifier: record.walletPassTypeIdentifier, library: library) {
            return stored
        }

        let candidates = candidateLibraryPasses(
            for: record,
            vaultRecords: vaultRecords,
            organizationName: organizationName,
            library: library
        )

        if !stored.isEmpty, candidates.contains(where: { $0.serialNumber == stored }) {
            return stored
        }
        if candidates.count == 1, let only = candidates.first {
            return only.serialNumber
        }

        if !stored.isEmpty {
            return stored
        }

        return "slip-\(record.id)"
    }

    static func candidateLibraryPasses(
        for record: PassVaultRecord,
        vaultRecords: [PassVaultRecord],
        organizationName: String?,
        library: PKPassLibrary = PKPassLibrary()
    ) -> [PKPass] {
        let claimed = Set(
            vaultRecords.compactMap { rec -> String? in
                guard rec.id != record.id else { return nil }
                let s = rec.walletSerialNumber?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                return s.isEmpty ? nil : s
            }
        )

        let org = organizationName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return library.passes().filter { pass in
            guard !claimed.contains(pass.serialNumber) else { return false }
            if let typeId = record.walletPassTypeIdentifier?
                .trimmingCharacters(in: .whitespacesAndNewlines),
               !typeId.isEmpty,
               pass.passTypeIdentifier != typeId {
                return false
            }
            if !org.isEmpty {
                return pass.organizationName.compare(org, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame
            }
            return false
        }
    }
}
