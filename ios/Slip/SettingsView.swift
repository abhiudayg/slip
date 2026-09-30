import SwiftUI

/// Artboard 5 — Account, Sync & APNs Settings
struct SettingsView: View {
    @AppStorage("slip.settings.gateAlerts") private var gateAlerts = true
    @AppStorage("slip.settings.liveActivity") private var liveActivity = true
    @AppStorage("slip.settings.watchMirroring") private var watchMirroring = true
    @AppStorage("slip.settings.expressTransit") private var expressTransit = true
    var onDone: (() -> Void)? = nil

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                topBar
                titleBlock
                profileCard
                section(title: "Live Updates & APNs Push") {
                    toggleRow(
                        icon: "bell.badge.fill",
                        tint: SlipTheme.accent,
                        title: "Gate & Turnstile Alerts",
                        subtitle: "Instant push notifications when platform, turnstile, or boarding gate changes",
                        isOn: $gateAlerts
                    )
                    divider
                    toggleRow(
                        icon: "rectangle.on.rectangle.angled",
                        tint: SlipTheme.indigo,
                        title: "Live Activity & Island",
                        subtitle: "Persistent transit countdown timers on Lock Screen & Dynamic Island",
                        isOn: $liveActivity
                    )
                }
                section(title: "Spatial Awareness & Proximity") {
                    HStack(alignment: .top, spacing: 12) {
                        iconCircle("location.north.line.fill", tint: SlipTheme.accent)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Geofence Wakeup")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(SlipTheme.ink)
                            Text("Auto-presents passes within 100m radius of transit turnstiles")
                                .font(.caption)
                                .foregroundStyle(SlipTheme.muted)
                        }
                        Spacer()
                        Label("Always Allow", systemImage: "location.fill")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(SlipTheme.muted)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .background(Capsule().fill(Color.white.opacity(0.08)))
                    }
                }
                section(title: "Apple Ecosystem") {
                    toggleRow(
                        icon: "applewatch",
                        tint: SlipTheme.indigo,
                        title: "Apple Watch Mirroring",
                        subtitle: "Sync wallet manifests directly to watchOS Wrist Target",
                        isOn: $watchMirroring
                    )
                    divider
                    toggleRow(
                        icon: "wave.3.right",
                        tint: SlipTheme.accent,
                        title: "Express Transit Mode",
                        subtitle: "Tap gate scanners instantly without Face ID or passcode authentication",
                        isOn: $expressTransit
                    )
                }
                section(title: "Security & Hardware Encryption") {
                    HStack(alignment: .top, spacing: 12) {
                        iconCircle("brain.head.profile", tint: SlipTheme.magenta)
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("Apple Vision Engine")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(SlipTheme.ink)
                                Image(systemName: "checkmark.seal.fill")
                                    .foregroundStyle(SlipTheme.accent)
                                Spacer()
                                Text("A19 Bionic")
                                    .font(.caption2.weight(.semibold))
                                    .foregroundStyle(SlipTheme.muted)
                            }
                            Text("Zero cloud image uploads. Screenshots are parsed 100% locally on Apple Neural Engine using zero-knowledge private OCR.")
                                .font(.caption)
                                .foregroundStyle(SlipTheme.muted)
                        }
                    }
                    divider
                    HStack(spacing: 12) {
                        iconCircle("checkmark.shield.fill", tint: SlipTheme.upiGreen)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("PassKit Developer Cert")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(SlipTheme.ink)
                            Text("BMRCL · IRCTC · DMRC Root Credentials")
                                .font(.caption)
                                .foregroundStyle(SlipTheme.muted)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(SlipTheme.muted)
                    }
                }

                GlassCard(cornerRadius: 18, padding: 14) {
                    HStack {
                        Image(systemName: "lock.shield.fill")
                            .foregroundStyle(SlipTheme.ink)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Secure Enclave Vault")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(SlipTheme.ink)
                            Text("E2E Sync Key: SHA-256 Verified")
                                .font(.caption2)
                                .foregroundStyle(SlipTheme.muted)
                        }
                        Spacer()
                        Text("256-BIT")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(SlipTheme.accentSoft)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(Capsule().fill(SlipTheme.accent.opacity(0.15)))
                    }
                }

                Button {} label: {
                    Label("Sign Out of iCloud Sync", systemImage: "rectangle.portrait.and.arrow.right")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Capsule().fill(Color(hex: 0x93000A)))
                }
                .buttonStyle(.plain)

                VStack(spacing: 4) {
                    Text("Slip v1.0")
                        .font(.caption2.weight(.semibold))
                        .tracking(0.6)
                        .textCase(.uppercase)
                        .foregroundStyle(SlipTheme.muted)
                    Text("Designed with Cupertino Precision")
                        .font(.caption)
                        .italic()
                        .foregroundStyle(SlipTheme.muted.opacity(0.8))
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 8)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 120)
        }
    }

    private var topBar: some View {
        HStack {
            HStack(spacing: 8) {
                SlipBrandMark(size: 26)
                Text("Settings")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(SlipTheme.ink)
            }
            Spacer()
            Image(systemName: "magnifyingglass")
                .foregroundStyle(SlipTheme.muted)
            Image(systemName: "person.crop.circle.fill")
                .font(.title2)
                .foregroundStyle(SlipTheme.indigo)
        }
    }

    private var titleBlock: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Settings & Sync")
                    .font(.system(size: 30, weight: .bold))
                    .tracking(-0.5)
                    .foregroundStyle(SlipTheme.ink)
                Text("Slip Hub")
                    .font(.caption.weight(.semibold))
                    .tracking(0.8)
                    .textCase(.uppercase)
                    .foregroundStyle(SlipTheme.muted)
            }
            Spacer()
            if let onDone {
                Button("Done", action: onDone)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(SlipTheme.canvasDeep)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(Color.white.opacity(0.95)))
            }
        }
    }

    private var profileCard: some View {
        GlassCard(cornerRadius: 24, padding: 16) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 12) {
                    Circle()
                        .fill(SlipTheme.indigo.opacity(0.4))
                        .frame(width: 54, height: 54)
                        .overlay(
                            Text("A")
                                .font(.title2.weight(.bold))
                                .foregroundStyle(.white)
                        )
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Text("Abhiuday")
                                .font(.headline)
                                .foregroundStyle(SlipTheme.ink)
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundStyle(SlipTheme.accent)
                        }
                        Text("abhiuday@icloud.com")
                            .font(.caption)
                            .foregroundStyle(SlipTheme.muted)
                        Text("Apple ID Verified")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(SlipTheme.indigo)
                    }
                }
                HStack {
                    Label("Slip Pro", systemImage: "crown.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(SlipTheme.ink)
                    Text("iCloud Vault Active")
                        .font(.caption2)
                        .foregroundStyle(SlipTheme.muted)
                    Spacer()
                    StatusPill(title: "Synced", tint: SlipTheme.upiGreen)
                }
                .padding(.top, 4)
                .padding(.horizontal, 4)
            }
        }
    }

    private func section<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.caption.weight(.semibold))
                .tracking(0.8)
                .textCase(.uppercase)
                .foregroundStyle(SlipTheme.muted)
            GlassCard(cornerRadius: 22, padding: 16) {
                VStack(alignment: .leading, spacing: 14) {
                    content()
                }
            }
        }
    }

    private func toggleRow(
        icon: String,
        tint: Color,
        title: String,
        subtitle: String,
        isOn: Binding<Bool>
    ) -> some View {
        HStack(alignment: .top, spacing: 12) {
            iconCircle(icon, tint: tint)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(SlipTheme.ink)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(SlipTheme.muted)
            }
            Spacer(minLength: 8)
            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(SlipTheme.indigo)
        }
    }

    private func iconCircle(_ systemName: String, tint: Color) -> some View {
        Image(systemName: systemName)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.white)
            .frame(width: 36, height: 36)
            .background(Circle().fill(tint.opacity(0.85)))
    }

    private var divider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.08))
            .frame(height: 0.5)
            .padding(.leading, 48)
    }
}
