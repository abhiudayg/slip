import Foundation
import UIKit
import UserNotifications

/// Lightweight local “mailbox/SMS” on-ramp: watch clipboard (and Share Extension text)
/// for IRCTC / airline / Airbnb / BMS booking bodies and nudge the user to import.
enum BookingInboxWatcher {
    static let enabledKey = "slip.booking.clipboardWatch"
    static let lastFingerprintKey = "slip.booking.lastClipboardFingerprint"
    static let notificationId = "slip.booking.clipboard.nudge"
    static let categoryId = "slip.booking.import"

    static var isEnabled: Bool {
        get { UserDefaults.standard.object(forKey: enabledKey) as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: enabledKey) }
    }

    /// Call when the app becomes active — never silently reads without a booking signal.
    @MainActor
    static func scanClipboardIfNeeded() async {
        guard isEnabled else { return }
        
        // On iOS 15+, pre-filter using detection patterns to avoid paste banner 
        // when the clipboard clearly doesn't contain a booking (no numbers or URLs).
        let hasPotentialBooking: Bool
        if #available(iOS 15.0, *) {
            hasPotentialBooking = UIPasteboard.general.hasStrings || UIPasteboard.general.hasURLs
        } else {
            hasPotentialBooking = UIPasteboard.general.hasStrings
        }
        
        guard hasPotentialBooking,
              let text = UIPasteboard.general.string,
              text.count >= 48 else { return }

        guard let hit = detect(in: text) else { return }

        let fingerprint = fingerprint(for: text)
        if UserDefaults.standard.string(forKey: lastFingerprintKey) == fingerprint { return }
        UserDefaults.standard.set(fingerprint, forKey: lastFingerprintKey)

        PendingBookingImport.save(text: text, brandHint: hit.brand)

        _ = await BookingReminderScheduler.requestAuthorization()
        let content = UNMutableNotificationContent()
        content.title = hit.notificationTitle
        content.body = "Add this \(hit.brandLabel) booking to Slip?"
        content.sound = .default
        content.categoryIdentifier = categoryId
        content.userInfo = ["brandHint": hit.brand, "source": "clipboard"]

        let req = UNNotificationRequest(
            identifier: notificationId,
            content: content,
            trigger: nil
        )
        try? await UNUserNotificationCenter.current().add(req)
        SlipHaptics.scrollTick()
    }

    struct Hit {
        var brand: String
        var brandLabel: String
        var notificationTitle: String
    }

    static func detect(in text: String) -> Hit? {
        let lower = text.lowercased()

        if lower.contains("irctc")
            || (lower.contains("pnr") && (lower.contains("train") || lower.contains("coach"))) {
            return Hit(brand: "irctc", brandLabel: "IRCTC", notificationTitle: "Train booking detected")
        }
        if lower.contains("indigo") || lower.contains("6e-") || lower.contains("boarding pass")
            || lower.contains("indigoairlines") {
            return Hit(brand: "indigo", brandLabel: "flight", notificationTitle: "Flight booking detected")
        }
        if lower.contains("airbnb") || (lower.contains("check-in") && lower.contains("reservation")) {
            return Hit(brand: "airbnb", brandLabel: "Airbnb", notificationTitle: "Stay booking detected")
        }
        if lower.contains("bookmyshow") || (lower.contains("bms") && lower.contains("seat"))
            || lower.contains("district by zomato") {
            return Hit(brand: "bookmyshow", brandLabel: "movie/event", notificationTitle: "Ticket booking detected")
        }
        if lower.contains("redbus") || lower.contains("bus ticket") {
            return Hit(brand: "redbus", brandLabel: "bus", notificationTitle: "Bus booking detected")
        }
        if lower.contains("confirmation") && (lower.contains("flight") || lower.contains("pnr")) {
            return Hit(brand: "indigo", brandLabel: "flight", notificationTitle: "Travel booking detected")
        }
        return nil
    }


    /// Non-notifying clipboard probe for Marketplace UI.
    @MainActor
    static func clipboardBookingIfAvailable() -> (text: String, hit: Hit)? {
        guard isEnabled else { return nil }
        guard let text = UIPasteboard.general.string, text.count >= 48 else { return nil }
        guard let hit = detect(in: text) else { return nil }
        return (text, hit)
    }

    private static func fingerprint(for text: String) -> String {
        let sample = String(text.prefix(400))
        return String(sample.hashValue)
    }
}

/// Staging area for clipboard / Mail share text awaiting confirm.
enum PendingBookingImport {
    private static let textKey = "slip.pending.bookingText"
    private static let brandKey = "slip.pending.brandHint"

    static func save(text: String, brandHint: String) {
        let defaults = UserDefaults(suiteName: SharedInbox.appGroupId) ?? .standard
        // Encrypt booking text before persisting to App Group.
        if let sealed = try? VaultCrypto.seal(text),
           let data = try? JSONEncoder().encode(sealed) {
            defaults.set(data, forKey: textKey)
        }
        defaults.set(brandHint, forKey: brandKey)
    }

    /// Read without clearing — used by Marketplace banner.
    static func peek() -> (text: String, brandHint: String)? {
        load(clearing: false)
    }

    static func consume() -> (text: String, brandHint: String)? {
        load(clearing: true)
    }

    private static func load(clearing: Bool) -> (text: String, brandHint: String)? {
        let defaults = UserDefaults(suiteName: SharedInbox.appGroupId) ?? .standard
        guard let data = defaults.data(forKey: textKey) else { return nil }
        let brand = defaults.string(forKey: brandKey) ?? ""
        if clearing {
            defaults.removeObject(forKey: textKey)
            defaults.removeObject(forKey: brandKey)
        }
        guard let box = try? JSONDecoder().decode(VaultCrypto.SealedBox.self, from: data),
              let text = try? VaultCrypto.open(box, as: String.self),
              !text.isEmpty else {
            return nil
        }
        return (text, brand)
    }

    static var hasPending: Bool {
        let defaults = UserDefaults(suiteName: SharedInbox.appGroupId) ?? .standard
        return defaults.data(forKey: textKey) != nil
    }
}
