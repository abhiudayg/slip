import Foundation

/// One traveler / boarding stub on a multi-entry ticket (IRCTC party, IndiGo PDF, etc.).
struct PassengerSeatEntry: Equatable, Sendable {
    var passenger: String
    var coach: String = ""
    var seat: String = ""
    var berthType: String = ""
    var gate: String = ""
    var flight: String = ""
    var pnr: String = ""
    var qrData: String = ""
}

/// Expands a single OCR classification into one ClassificationResult per traveler
/// so Slip creates separate vault + Wallet passes.
enum PassTravelerSplit {
    static func expand(_ base: ClassificationResult) -> [ClassificationResult] {
        let text = base.extracted.recognizedText
        let entries: [PassengerSeatEntry]
        switch base.templateId {
        case "irctc":
            entries = IRCTCPassLogic.extractPassengerEntries(from: text)
        case "indigo":
            entries = IndigoPassLogic.extractPassengerEntries(from: text)
        default:
            entries = []
        }

        guard entries.count >= 2 else { return [base] }

        let shared = base.fields
        return entries.enumerated().map { index, entry in
            var fields = shared
            fields["passenger"] = entry.passenger
            if !entry.coach.isEmpty { fields["coach"] = entry.coach }
            if !entry.seat.isEmpty { fields["seat"] = entry.seat }
            if !entry.berthType.isEmpty { fields["berth_type"] = entry.berthType }
            if !entry.gate.isEmpty { fields["gate"] = entry.gate }
            if !entry.flight.isEmpty { fields["flight"] = entry.flight }
            if !entry.pnr.isEmpty { fields["pnr"] = entry.pnr }
            if !entry.qrData.isEmpty {
                fields["qr_data"] = entry.qrData
            } else if let pnr = fields["pnr"], !pnr.isEmpty {
                // Same PNR barcode is fine; Wallet serial still unique per vault row.
                fields["qr_data"] = pnr
            }
            var copy = base
            copy.fields = fields
            copy.displayName = travelerDisplayName(base: base, passenger: entry.passenger, index: index, total: entries.count)
            copy.rationale = "\(base.rationale) · passenger \(index + 1)/\(entries.count)"
            // Stable unique id for sheet identity
            copy.createdAt = base.createdAt.addingTimeInterval(TimeInterval(index) * 0.001)
            return copy
        }
    }

    private static func travelerDisplayName(
        base: ClassificationResult,
        passenger: String,
        index: Int,
        total: Int
    ) -> String {
        let brand = base.displayName
        let name = passenger.trimmingCharacters(in: .whitespacesAndNewlines)
        if name.isEmpty {
            return "\(brand) · \(index + 1)/\(total)"
        }
        return "\(brand) · \(name)"
    }
}
