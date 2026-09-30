import AppIntents
import Foundation

/// Siri / Shortcuts entry: create a Slip pass from booking text.
struct CreatePassFromTextIntent: AppIntent {
    static var title: LocalizedStringResource = "Create Slip Pass"
    static var description = IntentDescription("Extract ticket fields and open Slip to confirm a Wallet pass.")
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
            intent: CreatePassFromTextIntent(),
            phrases: [
                "Create a \(.applicationName) pass from this booking",
                "Add this ticket to \(.applicationName)",
                "Fill a \(.applicationName) pass"
            ],
            shortTitle: "Create Pass",
            systemImageName: "wallet.pass"
        )
    }
}
