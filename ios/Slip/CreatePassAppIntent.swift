import AppIntents
import Foundation

/// Siri / Shortcuts entry: create a Slip pass from booking text (OCR-path fallback).
struct CreatePassFromTextIntent: AppIntent {
    static var title: LocalizedStringResource = "Create Slip Pass from Text"
    static var description = IntentDescription("Extract ticket fields from pasted booking text and open Slip to confirm.")
    static var openAppWhenRun: Bool = true

    @Parameter(title: "Booking text")
    var bookingText: String

    @Parameter(title: "QR or barcode payload")
    var barcodePayload: String?

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let barcode = barcodePayload ?? ""
        let extracted = TicketExtractor.extract(
            payload: barcode,
            symbology: barcode.isEmpty ? "none" : "qr",
            surroundingText: bookingText
        )
        let classification = await IntelligentBrandClassifier.classify(extracted)
        SharedInbox.save(classification)
        return .result(dialog: IntentDialog(stringLiteral: "Slip has a \(classification.displayName) pass ready to confirm."))
    }
}

struct SlipAppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: SlipAddPassIntent(),
            phrases: [
                "Add my \(.applicationName) ticket",
                "Add a BookMyShow ticket to \(.applicationName)",
                "Save this booking in \(.applicationName)"
            ],
            shortTitle: "Add Pass",
            systemImageName: "ticket"
        )
        AppShortcut(
            intent: CreatePassFromTextIntent(),
            phrases: [
                "Create a \(.applicationName) pass from this booking",
                "Fill a \(.applicationName) pass from text"
            ],
            shortTitle: "Create from Text",
            systemImageName: "wallet.pass"
        )
    }
}
