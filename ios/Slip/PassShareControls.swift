import SwiftUI

/// Share a vault pass via iMessage / AirDrop using a `slip://import/…` deep link.
struct PassShareControls: View {
    let package: PassSharePackage

    var body: some View {
        if let url = package.deepLink() {
            ShareLink(
                item: url,
                subject: Text(package.displayName),
                message: Text("Here's your \(package.displayName) pass for Slip. Tap to import into your vault.")
            ) {
                Label("Share pass", systemImage: "square.and.arrow.up")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(SlipTheme.ink)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Capsule().fill(SlipTheme.cardHigh))
                    .overlay(Capsule().strokeBorder(Color.white.opacity(0.12), lineWidth: 1))
            }
            .simultaneousGesture(TapGesture().onEnded { SlipHaptics.shareReady() })
        }
    }
}

/// Lightweight CloudKit shared-zone on-ramp (family wallet).
struct FamilyVaultShareCard: View {
    @State private var status = "Invite a partner to a shared Slip vault (CloudKit Shared Zone)."
    @State private var busy = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Shared family vault")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(SlipTheme.ink)
            Text(status)
                .font(.caption)
                .foregroundStyle(SlipTheme.muted)
            Button {
                Task { await prepareShare() }
            } label: {
                Text(busy ? "Preparing…" : "Create share link")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(SlipTheme.accent)
            }
            .disabled(busy)
        }
    }

    private func prepareShare() async {
        busy = true
        defer { busy = false }
        // Full CKShare zone wiring needs production container entitlements;
        // surface a clear next-step for TestFlight builds.
        let ok = await FamilyVaultShare.ensureSharedZone()
        status = ok
            ? "Shared zone ready — open Settings → iCloud to manage participants."
            : "CloudKit share unavailable on this build. Ciphertext sync still works privately."
    }
}

enum FamilyVaultShare {
    static func ensureSharedZone() async -> Bool {
        // Placeholder until CKShare + participant UI ships with App Store container.
        // Returns false so UI stays honest; private CloudKit sync remains unchanged.
        false
    }
}
