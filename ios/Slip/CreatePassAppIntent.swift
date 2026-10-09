import AppIntents
import Foundation
import UIKit

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

/// Shared import path for clipboard / Mail-copy booking bodies.
enum BookingMailImport {
    /// Returns a Siri dialog string. Saves classification into SharedInbox for the host app.
    @MainActor
    static func importBookingBody(_ preferredText: String? = nil) async -> String {
        let text: String
        if let preferred = preferredText?.trimmingCharacters(in: .whitespacesAndNewlines),
           preferred.count >= 24 {
            text = preferred
        } else if let clip = UIPasteboard.general.string?.trimmingCharacters(in: .whitespacesAndNewlines),
                  clip.count >= 24 {
            text = clip
        } else {
            return "Open the booking in Mail, copy the email body or tap Share → Slip, then try again."
        }

        let brand = BookingInboxWatcher.detect(in: text)?.brand
        PendingBookingImport.save(text: text, brandHint: brand ?? "")
        let extracted = TicketExtractor.extract(payload: "", symbology: "none", surroundingText: text)
        let classification = await IntelligentBrandClassifier.classify(extracted)
        SharedInbox.save(classification)
        return "Slip has a \(classification.displayName) pass ready to confirm."
    }
}

/// Pull booking text from the clipboard (Mail / SMS copy) and open confirm.
struct ImportBookingFromClipboardIntent: AppIntent {
    static var title: LocalizedStringResource = "Import Booking from Clipboard"
    static var description = IntentDescription(
        "Detect IRCTC, airline, or Airbnb booking text on the clipboard and open Slip to confirm."
    )
    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let dialog = await BookingMailImport.importBookingBody(nil)
        return .result(dialog: IntentDialog(stringLiteral: dialog))
    }
}

/// Siri phrases for booking emails. Cannot read the Mail inbox — uses clipboard / Shortcuts text /
/// or the Share → Slip path from Mail.
struct ImportBookingFromMailIntent: AppIntent {
    static var title: LocalizedStringResource = "Import Booking Email"
    static var description = IntentDescription(
        "Import a booking confirmation into Slip. Open the email in Mail, copy the body or Share to Slip, then run this shortcut."
    )
    static var openAppWhenRun: Bool = true

    @Parameter(title: "Booking email text")
    var bookingText: String?

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let dialog = await BookingMailImport.importBookingBody(bookingText)
        return .result(dialog: IntentDialog(stringLiteral: dialog))
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
            intent: ShowSlipPassIntent(),
            phrases: [
                "Show my \(.applicationName) pass",
                "Open my \(.applicationName) ticket",
                "Show my boarding pass in \(.applicationName)"
            ],
            shortTitle: "Show Pass",
            systemImageName: "qrcode"
        )
        AppShortcut(
            intent: FindSlipPassIntent(),
            phrases: [
                "Find my ticket in \(.applicationName)",
                "Find my flight in \(.applicationName)",
                "Find my BookMyShow ticket in \(.applicationName)"
            ],
            shortTitle: "Find Pass",
            systemImageName: "magnifyingglass"
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
        AppShortcut(
            intent: ImportBookingFromClipboardIntent(),
            phrases: [
                "Import booking from clipboard in \(.applicationName)",
                "Add clipboard booking to \(.applicationName)"
            ],
            shortTitle: "Import Clipboard",
            systemImageName: "doc.on.clipboard"
        )
        AppShortcut(
            intent: ImportBookingFromMailIntent(),
            phrases: [
                "Import booking email in \(.applicationName)",
                "Import this email into \(.applicationName)",
                "Add this booking email to \(.applicationName)",
                "Save Mail booking in \(.applicationName)"
            ],
            shortTitle: "Import Email",
            systemImageName: "envelope.badge"
        )
    }
}
