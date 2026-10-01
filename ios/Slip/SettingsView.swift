import PhotosUI
import SwiftUI

/// Artboard 5 — Account, Sync & APNs Settings
struct SettingsView: View {
    @EnvironmentObject private var auth: AuthSession
    @EnvironmentObject private var vault: PassVaultStore
    @EnvironmentObject private var geofence: PassGeofenceManager
    @AppStorage("slip.settings.gateAlerts") private var gateAlerts = true
    @AppStorage("slip.settings.liveActivity") private var liveActivity = true
    @AppStorage("slip.settings.watchMirroring") private var watchMirroring = true
    @AppStorage("slip.settings.expressTransit") private var expressTransit = true
    @State private var avatarPickerItem: PhotosPickerItem?
    @State private var isEditingName = false
    @State private var draftName = ""
    @State private var geminiAPIKey = ""
    @State private var geminiKeySaved = false
    @State private var aviationAPIKey = ""
    var onDone: (() -> Void)? = nil

    private var profileName: String {
        let name = auth.displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !name.isEmpty { return name }
        if !auth.email.isEmpty { return auth.email }
        return "Add your name"
    }

    private var liveActivitySubtitle: String {
        if !liveActivity {
            return "Off — new passes will not start a Dynamic Island Live Activity"
        }
        if PassLiveActivityController.areActivitiesEnabled {
            return "On — Slip starts a Lock Screen / Dynamic Island activity when you generate a pass"
        }
        return "Enabled in Slip, but Live Activities are turned off in iOS Settings → Slip"
    }

    private var geofenceSubtitle: String {
        switch geofence.authorizationStatus {
        case .authorizedAlways:
            let plural = geofence.monitoredRegionCount == 1 ? "" : "s"
            return "Always on — monitoring \(geofence.monitoredRegionCount) station region\(plural)"
        case .authorizedWhenInUse:
            return "While Using only — tap to upgrade to Always for background geofence wakeups"
        case .denied, .restricted:
            return "Blocked — enable Location → Always for Slip in iOS Settings"
        case .notDetermined:
            return "Tap to allow Always location so Slip can surface passes near metro stations"
        @unknown default:
            return "Location status unknown"
        }
    }

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
                        subtitle: liveActivitySubtitle,
                        isOn: $liveActivity
                    )
                }
                section(title: "Spatial Awareness & Proximity") {
                    Button {
                        geofence.requestAccess()
                    } label: {
                        HStack(alignment: .top, spacing: 12) {
                            iconCircle("location.north.line.fill", tint: SlipTheme.accent)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Geofence Wakeup")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(SlipTheme.ink)
                                Text(geofenceSubtitle)
                                    .font(.caption)
                                    .foregroundStyle(SlipTheme.muted)
                                    .multilineTextAlignment(.leading)
                                if let err = geofence.lastError {
                                    Text(err)
                                        .font(.caption2)
                                        .foregroundStyle(.orange)
                                }
                            }
                            Spacer()
                            Text(geofence.shortLabel)
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(geofence.isGranted ? SlipTheme.upiGreen : SlipTheme.muted)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 8)
                                .background(Capsule().fill(Color.white.opacity(0.08)))
                        }
                    }
                    .buttonStyle(.plain)
                }
                section(title: "Apple Ecosystem") {
                    HStack(alignment: .top, spacing: 12) {
                        iconCircle("iphone", tint: SlipTheme.accent)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("iOS only (v1)")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(SlipTheme.ink)
                            Text("Slip ships for iPhone first. Android and desktop are not supported yet.")
                                .font(.caption)
                                .foregroundStyle(SlipTheme.muted)
                        }
                        Spacer()
                        StatusPill(title: "iOS", tint: SlipTheme.upiGreen, filled: true)
                    }
                    divider
                    toggleRow(
                        icon: "applewatch",
                        tint: SlipTheme.indigo,
                        title: "Apple Watch + Home Widget",
                        subtitle: "Unlock vault to sync QRs. Add “Slip Pass QR” from the widget gallery; Watch lists relevant passes.",
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

                section(title: "Hybrid AI Extraction") {
                    HStack(alignment: .top, spacing: 12) {
                        iconCircle("sparkles", tint: SlipTheme.indigo)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Anchors first, fuzzy second")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(SlipTheme.ink)
                            Text("Vision + regex lock QR / PNR / booking IDs. Apple Intelligence (or optional Gemini) only fills missing movie, restaurant, and venue names.")
                                .font(.caption)
                                .foregroundStyle(SlipTheme.muted)
                        }
                    }
                    divider
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Gemini API key (optional fallback)")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(SlipTheme.muted)
                        SecureField("AIza…", text: $geminiAPIKey)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .font(.subheadline.monospaced())
                            .padding(12)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.06)))
                            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.white.opacity(0.1), lineWidth: 1))
                        HStack {
                            Button("Save key") {
                                let trimmed = geminiAPIKey.trimmingCharacters(in: .whitespacesAndNewlines)
                                UserDefaults.standard.set(trimmed, forKey: GeminiFuzzyFiller.apiKeyDefaultsKey)
                                UserDefaults(suiteName: SharedInbox.appGroupId)?
                                    .set(trimmed, forKey: GeminiFuzzyFiller.apiKeyDefaultsKey)
                                geminiKeySaved = true
                            }
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(SlipTheme.accent)
                            if geminiKeySaved || !(GeminiFuzzyFiller.apiKey ?? "").isEmpty {
                                Text("Saved on device")
                                    .font(.caption2)
                                    .foregroundStyle(SlipTheme.upiGreen)
                            }
                            Spacer()
                            Button("Clear") {
                                geminiAPIKey = ""
                                UserDefaults.standard.removeObject(forKey: GeminiFuzzyFiller.apiKeyDefaultsKey)
                                UserDefaults(suiteName: SharedInbox.appGroupId)?
                                    .removeObject(forKey: GeminiFuzzyFiller.apiKeyDefaultsKey)
                                geminiKeySaved = false
                            }
                            .font(.caption)
                            .foregroundStyle(SlipTheme.muted)
                        }
                    }
                }

                section(title: "Live Tracking & Reminders") {
                    HStack(alignment: .top, spacing: 12) {
                        iconCircle("airplane.departure", tint: SlipTheme.indigo)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Flight / train Live Activity")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(SlipTheme.ink)
                            Text("Optional AviationStack key updates gate & delay on Dynamic Island. Booking reminders fire locally the evening before.")
                                .font(.caption)
                                .foregroundStyle(SlipTheme.muted)
                        }
                    }
                    divider
                    VStack(alignment: .leading, spacing: 8) {
                        Text("AviationStack API key (optional)")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(SlipTheme.muted)
                        SecureField("key…", text: $aviationAPIKey)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .font(.subheadline.monospaced())
                            .padding(12)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.06)))
                        Button("Save tracking key") {
                            let trimmed = aviationAPIKey.trimmingCharacters(in: .whitespacesAndNewlines)
                            UserDefaults.standard.set(trimmed, forKey: LiveStatusService.apiKeyDefaultsKey)
                            UserDefaults(suiteName: SharedInbox.appGroupId)?
                                .set(trimmed, forKey: LiveStatusService.apiKeyDefaultsKey)
                        }
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(SlipTheme.accent)
                    }
                    divider
                    FamilyVaultShareCard()
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

                Button {
                    vault.lock()
                    auth.signOut()
                } label: {
                    Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Capsule().fill(Color(hex: 0x93000A)))
                }
                .buttonStyle(.plain)

                VStack(spacing: 4) {
                    Text("Slip v1.0 · Built for iOS")
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
        .onAppear {
            geminiAPIKey = UserDefaults.standard.string(forKey: GeminiFuzzyFiller.apiKeyDefaultsKey)
                ?? UserDefaults(suiteName: SharedInbox.appGroupId)?.string(forKey: GeminiFuzzyFiller.apiKeyDefaultsKey)
                ?? ""
            aviationAPIKey = UserDefaults.standard.string(forKey: LiveStatusService.apiKeyDefaultsKey)
                ?? UserDefaults(suiteName: SharedInbox.appGroupId)?.string(forKey: LiveStatusService.apiKeyDefaultsKey)
                ?? ""
        }
        .onChange(of: avatarPickerItem) { _, item in
            guard let item else { return }
            Task {
                await applyPickedAvatar(item)
            }
        }
    }

    private var topBar: some View {
        StudioTopBar(title: "Settings", onSearch: {}) {
            ProfileAvatarView(
                image: auth.avatarImage,
                monogram: auth.monogram,
                size: 32
            )
        }
    }

    private var titleBlock: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Settings & Sync")
                    .font(.system(size: 28, weight: .semibold))
                    .tracking(-0.5)
                    .foregroundStyle(SlipTheme.ink)
                Text("Slip iOS Hub")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(0.9)
                    .textCase(.uppercase)
                    .foregroundStyle(SlipTheme.muted)
            }
            Spacer()
            if let onDone {
                Button("Done", action: onDone)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(SlipTheme.ink)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(SlipTheme.cardHigh))
                    .overlay(Capsule().strokeBorder(Color.white.opacity(0.12), lineWidth: 1))
            }
        }
    }

    private var profileCard: some View {
        GlassCard(cornerRadius: 24, padding: 16) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 12) {
                    profileAvatarPicker

                    VStack(alignment: .leading, spacing: 4) {
                        Button {
                            draftName = auth.needsDisplayName ? "" : auth.displayName
                            isEditingName = true
                        } label: {
                            HStack(spacing: 6) {
                                Text(profileName)
                                    .font(.headline)
                                    .foregroundStyle(SlipTheme.ink)
                                Image(systemName: "pencil")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(SlipTheme.muted)
                                Image(systemName: "checkmark.seal.fill")
                                    .foregroundStyle(SlipTheme.accent)
                            }
                        }
                        .buttonStyle(.plain)

                        if !auth.email.isEmpty {
                            Text(auth.email)
                                .font(.caption)
                                .foregroundStyle(SlipTheme.muted)
                                .lineLimit(1)
                        } else {
                            Text(auth.isSignedIn ? "Signed in with Apple" : "Not signed in")
                                .font(.caption)
                                .foregroundStyle(SlipTheme.muted)
                        }
                        if auth.isSignedIn {
                            Text("Apple ID Verified")
                                .font(.system(size: 11, weight: .semibold))
                                .tracking(0.5)
                                .textCase(.uppercase)
                                .foregroundStyle(SlipTheme.accentSoft)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Capsule().fill(SlipTheme.accent.opacity(0.18)))
                        }
                        Text(auth.avatarImage == nil
                             ? "Tap avatar to add a photo (Apple Sign In doesn’t provide one)"
                             : "Tap name to edit · tap camera to change photo")
                            .font(.caption2)
                            .foregroundStyle(SlipTheme.muted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(SlipTheme.accentSoft)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Always Free")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(SlipTheme.ink)
                        Text("iCloud Vault Active")
                            .font(.system(size: 11, weight: .semibold))
                            .tracking(0.4)
                            .textCase(.uppercase)
                            .foregroundStyle(SlipTheme.muted)
                    }
                    Spacer()
                    StatusPill(title: "Synced", tint: SlipTheme.accentSoft, systemImage: "checkmark.icloud.fill")
                }
                .padding(.top, 4)
                .padding(.horizontal, 4)
            }
        }
        .alert("Your name", isPresented: $isEditingName) {
            TextField("Name", text: $draftName)
                .textInputAutocapitalization(.words)
            Button("Save") {
                auth.updateDisplayName(draftName)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Apple only sends your name the first time you sign in. You can set or fix it here anytime.")
        }
    }

    @ViewBuilder
    private var profileAvatarPicker: some View {
        let image = auth.avatarImage
        let monogram = auth.monogram
        let signedIn = auth.isSignedIn
        PhotosPicker(selection: $avatarPickerItem, matching: .images, photoLibrary: .shared()) {
            ZStack(alignment: .bottomTrailing) {
                ProfileAvatarView(
                    image: image,
                    monogram: monogram,
                    size: 64
                )
                .overlay(
                    Circle()
                        .strokeBorder(
                            LinearGradient(
                                colors: [SlipTheme.accentSoft.opacity(0.7), SlipTheme.accent.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                )
                Image(systemName: signedIn ? "checkmark.icloud.fill" : "camera.fill")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(5)
                    .background(Circle().fill(SlipTheme.accent))
                    .overlay(Circle().strokeBorder(SlipTheme.canvasDeep, lineWidth: 2))
                    .offset(x: 2, y: 2)
            }
        }
        .buttonStyle(.plain)
        .contextMenu {
            if image != nil {
                Button("Remove Photo", role: .destructive) {
                    auth.updateAvatar(nil)
                }
            }
        }
        .accessibilityLabel("Change profile photo")
    }

    private func applyPickedAvatar(_ item: PhotosPickerItem) async {

        do {
            if let data = try await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                auth.updateAvatar(image)
            }
        } catch {
            // Keep existing avatar on failure.
        }
        avatarPickerItem = nil
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
                .tint(SlipTheme.accent)
                        .tint(SlipTheme.accent)
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
