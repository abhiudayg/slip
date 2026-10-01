import UIKit

/// Tuned Taptic patterns for wallet actions.
enum SlipHaptics {
    private static let heavy = UIImpactFeedbackGenerator(style: .heavy)
    private static let light = UIImpactFeedbackGenerator(style: .light)
    private static let soft = UIImpactFeedbackGenerator(style: .soft)
    private static let rigid = UIImpactFeedbackGenerator(style: .rigid)
    private static let notify = UINotificationFeedbackGenerator()
    private static let select = UISelectionFeedbackGenerator()

    static func prepare() {
        heavy.prepare()
        light.prepare()
        soft.prepare()
        rigid.prepare()
        notify.prepare()
        select.prepare()
    }

    /// Saved to vault / Wallet — solid thud.
    static func passSaved() {
        heavy.impactOccurred(intensity: 1.0)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            soft.impactOccurred(intensity: 0.6)
        }
    }

    /// Wallet list / brand grid scroll tick.
    static func scrollTick() {
        select.selectionChanged()
    }

    /// QR / barcode lock at turnstile or live scan.
    static func scanSuccess() {
        notify.notificationOccurred(.success)
        rigid.impactOccurred(intensity: 0.9)
    }

    /// Bright QR presented for scanner.
    static func brightQRReady() {
        soft.impactOccurred(intensity: 0.75)
    }

    static func shareReady() {
        light.impactOccurred(intensity: 0.7)
    }

    static func warning() {
        notify.notificationOccurred(.warning)
    }
}
