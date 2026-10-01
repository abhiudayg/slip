import PhotosUI
import SwiftUI

/// Artboard 5 — Account, Sync & APNs Settings (Stitch `settings_slip_wallet`).
@MainActor
struct SettingsView: View {
    @EnvironmentObject private var auth: AuthSession
    @EnvironmentObject private var vault: PassVaultStore
    @EnvironmentObject private var geofence: PassGeofenceManager

    @AppStorage("slip.settings.faceId") private var faceIdEnabled = true
    @AppStorage("slip.settings.nfcFaceId") private var requireNfcFaceId = true
    @AppStorage("slip.settings.autoArchive") private var autoArchiveExpired = true
    @AppStorage("slip.settings.cardStackPhysics") private var cardStackPhysics = true
    @AppStorage("slip.settings.haptics") private var hapticFeedback = true

    @AppStorage("slip.settings.gateAlerts") private var gateAlerts = true
    @AppStorage("slip.settings.liveActivity") private var liveActivity = true
    @AppStorage("slip.settings.watchMirroring") private var watchMirroring = true
    @AppStorage("slip.settings.expressTransit") private var expressTransit = true

    @State private var avatarPickerItem: PhotosPickerItem?
    @State private var isEditingName = false
    @State private var draftName = ""
    @State private var showResetConfirmation = false
    @State private var isSyncing = false
    @State private var syncToast = false
    @State private var showAdvanced = false
    @State private var aviationAPIKey = ""
    @State private var clipboardWatch = true
    @State private var showIdentityVault = false
    @StateObject private var identityStore = IdentityVaultStore.shared
    @State private var railProxyURL = ""
    var onDone: (() -> Void)? = nil

    private var profileName: String {
        let name = auth.displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !name.isEmpty { return name }
        if !auth.email.isEmpty { return auth.email }
        return "Alexander Vance"
    }

    private var profileEmail: String {
        if !auth.email.isEmpty { return auth.email }
        return "alexander.v@okhdfcbank"
    }

    var body: some View {
        SlipScreenColumn {
            topHeader.frame(maxWidth: .infinity, alignment: .leading)
            accountSection.frame(maxWidth: .infinity, alignment: .leading)
            securitySection.frame(maxWidth: .infinity, alignment: .leading)
            storageSection.frame(maxWidth: .infinity, alignment: .leading)
            appearanceSection.frame(maxWidth: .infinity, alignment: .leading)
            advancedSection.frame(maxWidth: .infinity, alignment: .leading)
            footer.frame(maxWidth: .infinity, alignment: .center)
        }
        .onAppear {
            aviationAPIKey = UserDefaults.standard.string(forKey: LiveStatusService.apiKeyDefaultsKey)
                ?? UserDefaults(suiteName: SharedInbox.appGroupId)?.string(forKey: LiveStatusService.apiKeyDefaultsKey)
                ?? ""
            clipboardWatch = BookingInboxWatcher.isEnabled
            railProxyURL = UserDefaults.standard.string(forKey: LiveStatusService.railProxyDefaultsKey)
                ?? UserDefaults(suiteName: SharedInbox.appGroupId)?.string(forKey: LiveStatusService.railProxyDefaultsKey)
                ?? ""
        }
        .onChange(of: avatarPickerItem) { _, item in
            guard let item else { return }
            Task {
                await applyPickedAvatar(item)
            }
        }
        .alert("Reset Vault & Sign Out?", isPresented: $showResetConfirmation) {
            Button("Reset & Sign Out", role: .destructive) {
                vault.lock()
                auth.signOut()
                onDone?()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("All locally cached decrypted passes and private session keys will be purged from the Secure Enclave.")
        }
        .alert("Your Name", isPresented: $isEditingName) {
            TextField("Name", text: $draftName)
                .textInputAutocapitalization(.words)
            Button("Save") {
                auth.updateDisplayName(draftName)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Apple only sends your name the first time you sign in. You can change how it appears on your passes here.")
        }
    }

    // MARK: - Header

    private var topHeader: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Button {
                    onDone?()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(SlipTheme.ink)
                        .frame(width: 36, height: 36)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(SlipTheme.cardHigh.opacity(0.6))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .strokeBorder(SlipTheme.glassBorder, lineWidth: 1)
                                )
                        )
                }
                .buttonStyle(.plain)

                Spacer()

                Text("VAULT PROTOCOL 2.4")
                    .font(SlipTheme.labelMono())
                    .tracking(1.4)
                    .foregroundStyle(SlipTheme.muted)

                Spacer()

                Button {
                    // Notification center
                } label: {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(SlipTheme.muted)
                        .frame(width: 36, height: 36)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(SlipTheme.cardHigh.opacity(0.6))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .strokeBorder(SlipTheme.glassBorder, lineWidth: 1)
                                )
                        )
                }
                .buttonStyle(.plain)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Settings")
                    .font(SlipTheme.headlineXL())
                    .tracking(-0.6)
                    .foregroundStyle(SlipTheme.ink)
                HStack(spacing: 8) {
                    Circle()
                        .fill(SlipTheme.upiGreen)
                        .frame(width: 7, height: 7)
                        .shadow(color: SlipTheme.upiGreen.opacity(0.8), radius: 3)
                    Text("PassKit & Security Vault")
                        .font(SlipTheme.bodySM())
                        .foregroundStyle(SlipTheme.muted)
                }
            }
        }
    }

    // MARK: - Section 1: Account & Credentials

    private var accountSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("ACCOUNT & CREDENTIALS")

            VStack(spacing: 0) {
                // Profile Row
                HStack(spacing: 14) {
                    PhotosPicker(selection: $avatarPickerItem, matching: .images) {
                        ZStack(alignment: .bottomTrailing) {
                            ProfileAvatarView(
                                image: auth.avatarImage,
                                monogram: auth.monogram,
                                size: 52
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .strokeBorder(SlipTheme.glassBorder, lineWidth: 1)
                            )

                            ZStack {
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .fill(Color(hex: 0x007AFF))
                                    .frame(width: 18, height: 18)
                                Image(systemName: "key.fill")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                            .offset(x: 3, y: 3)
                        }
                    }
                    .buttonStyle(.plain)

                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 8) {
                            Text(profileName)
                                .font(SlipTheme.headlineSM())
                                .foregroundStyle(SlipTheme.ink)
                            Text("PRO")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundStyle(SlipTheme.ink)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                                        .fill(SlipTheme.cardHigh)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                                .strokeBorder(SlipTheme.glassBorder, lineWidth: 1)
                                        )
                                )
                        }

                        Text(profileEmail)
                            .font(SlipTheme.bodySM())
                            .foregroundStyle(SlipTheme.muted)
                            .lineLimit(1)

                        HStack(spacing: 4) {
                            Image(systemName: "person.badge.key.fill")
                                .font(.system(size: 11))
                                .foregroundStyle(SlipTheme.muted)
                            Text("Apple ID Linked")
                                .font(SlipTheme.labelMono())
                                .foregroundStyle(SlipTheme.muted)
                        }
                        .padding(.top, 2)
                    }

                    Spacer()

                    Button {
                        draftName = auth.displayName
                        isEditingName = true
                    } label: {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(SlipTheme.muted)
                    }
                    .buttonStyle(.plain)
                }
                .padding(16)

                Divider().background(SlipTheme.glassBorder)

                // PassKit & Apple Wallet Sync Row
                HStack(spacing: 12) {
                    squircleIcon("wallet.pass.fill", color: Color(hex: 0x007AFF))

                    VStack(alignment: .leading, spacing: 2) {
                        Text("PassKit & Apple Wallet Sync")
                            .font(SlipTheme.bodyMD())
                            .fontWeight(.medium)
                            .foregroundStyle(SlipTheme.ink)
                        Text("Connected • Active")
                            .font(SlipTheme.labelMono())
                            .foregroundStyle(SlipTheme.upiGreen)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(SlipTheme.muted)
                }
                .padding(16)
            }
            .background(cardBackground)
        }
    }

    // MARK: - Section 2: Hardware & Biometric Security

    private var securitySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("HARDWARE & BIOMETRIC SECURITY")

            VStack(spacing: 0) {
                // Face ID & Passcode
                toggleRow(
                    icon: "faceid",
                    iconColor: SlipTheme.upiGreen,
                    title: "Face ID & Passcode",
                    subtitle: nil,
                    isOn: $faceIdEnabled
                )

                Divider().background(SlipTheme.glassBorder)

                // Require Face ID for NFC
                toggleRow(
                    icon: "wave.3.right",
                    iconColor: SlipTheme.upiGreen,
                    title: "Require Face ID for NFC",
                    subtitle: "Mandatory on turnstile tap",
                    isOn: $requireNfcFaceId
                )

                Divider().background(SlipTheme.glassBorder)

                // Passkey Management
                HStack(spacing: 12) {
                    squircleIcon("touchid", color: SlipTheme.upiGreen)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Passkey Management")
                            .font(SlipTheme.bodyMD())
                            .fontWeight(.medium)
                            .foregroundStyle(SlipTheme.ink)
                        Text("FIDO2 / WebAuthn vaults")
                            .font(SlipTheme.bodySM())
                            .foregroundStyle(SlipTheme.muted)
                    }

                    Spacer()

                    HStack(spacing: 6) {
                        Text("2 keys")
                            .font(SlipTheme.labelMono())
                            .foregroundStyle(SlipTheme.muted)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(SlipTheme.muted)
                    }
                }
                .padding(16)

                Divider().background(SlipTheme.glassBorder)

                // Secure Enclave Hardware
                HStack(spacing: 12) {
                    squircleIcon("shield.checkerboard", color: SlipTheme.upiGreen)

                    Text("Secure Enclave Hardware")
                        .font(SlipTheme.bodyMD())
                        .fontWeight(.medium)
                        .foregroundStyle(SlipTheme.ink)

                    Spacer()

                    Text("Level 3 Encrypted")
                        .font(SlipTheme.labelMono())
                        .foregroundStyle(SlipTheme.upiGreen)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(SlipTheme.upiGreen.opacity(0.12))
                                .overlay(Capsule().strokeBorder(SlipTheme.upiGreen.opacity(0.3), lineWidth: 1))
                        )
                }
                .padding(16)
            }
            .background(cardBackground)
        }
    }

    // MARK: - Section 3: Storage & Cloud Synchronisation

    private var storageSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("STORAGE & CLOUD SYNCHRONISATION")

            VStack(spacing: 0) {
                // iCloud Sync Row
                HStack(spacing: 12) {
                    squircleIcon("arrow.triangle.2.circlepath.icloud.fill", color: Color(hex: 0xA855F7))

                    VStack(alignment: .leading, spacing: 2) {
                        Text("iCloud Keychain & Vault Sync")
                            .font(SlipTheme.bodyMD())
                            .fontWeight(.medium)
                            .foregroundStyle(SlipTheme.ink)
                        Text("Last synced 2m ago")
                            .font(SlipTheme.labelMono())
                            .foregroundStyle(SlipTheme.muted)
                    }

                    Spacer()

                    Circle()
                        .fill(SlipTheme.upiGreen)
                        .frame(width: 8, height: 8)
                        .shadow(color: SlipTheme.upiGreen.opacity(0.8), radius: 3)
                }
                .padding(16)

                // Sync Now prominent button
                Button {
                    isSyncing = true
                    Task {
                        try? await Task.sleep(nanoseconds: 800_000_000)
                        isSyncing = false
                        syncToast = true
                        try? await Task.sleep(nanoseconds: 1_500_000_000)
                        syncToast = false
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: isSyncing ? "arrow.triangle.2.circlepath" : "arrow.clockwise")
                            .font(.system(size: 15, weight: .bold))
                            .rotationEffect(.degrees(isSyncing ? 360 : 0))
                            .animation(isSyncing ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: isSyncing)
                        Text(syncToast ? "Synced with iCloud!" : "Sync Now")
                            .font(SlipTheme.headlineSM())
                            .fontWeight(.semibold)
                    }
                    .foregroundStyle(Color.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.white)
                            .shadow(color: .white.opacity(0.15), radius: 10, y: 2)
                    )
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 16)
                .padding(.bottom, 16)

                Divider().background(SlipTheme.glassBorder)

                // Offline Pass Cache
                HStack(spacing: 12) {
                    squircleIcon("internaldrive.fill", color: Color(hex: 0xA855F7))

                    Text("Offline Pass Cache")
                        .font(SlipTheme.bodyMD())
                        .fontWeight(.medium)
                        .foregroundStyle(SlipTheme.ink)

                    Spacer()

                    HStack(spacing: 6) {
                        Text("\(max(vault.records.count, 4)) Passes cached")
                            .font(SlipTheme.labelMono())
                            .foregroundStyle(SlipTheme.muted)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(SlipTheme.muted)
                    }
                }
                .padding(16)

                Divider().background(SlipTheme.glassBorder)

                // Auto-Archive Expired Passes
                toggleRow(
                    icon: "archivebox.fill",
                    iconColor: Color(hex: 0xA855F7),
                    title: "Auto-Archive Expired Passes",
                    subtitle: "After 72 hours of validity",
                    isOn: $autoArchiveExpired
                )
            }
            .background(cardBackground)
        }
    }

    // MARK: - Section 4: Appearance & Haptics

    private var appearanceSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("APPEARANCE & HAPTICS")

            VStack(spacing: 0) {
                // Theme
                HStack(spacing: 12) {
                    squircleIcon("moon.fill", color: Color(hex: 0x64748B))

                    Text("Theme")
                        .font(SlipTheme.bodyMD())
                        .fontWeight(.medium)
                        .foregroundStyle(SlipTheme.ink)

                    Spacer()

                    HStack(spacing: 6) {
                        Text("Dark Mode (Pure Black)")
                            .font(SlipTheme.labelMono())
                            .foregroundStyle(SlipTheme.muted)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(SlipTheme.muted)
                    }
                }
                .padding(16)

                Divider().background(SlipTheme.glassBorder)

                // Card Stack Animation
                toggleRow(
                    icon: "square.stack.3d.up.fill",
                    iconColor: Color(hex: 0x64748B),
                    title: "Card Stack Animation",
                    subtitle: "Tactile 3D physics",
                    isOn: $cardStackPhysics
                )

                Divider().background(SlipTheme.glassBorder)

                // Haptic Feedback
                toggleRow(
                    icon: "iphone.radiowaves.left.and.right",
                    iconColor: Color(hex: 0x64748B),
                    title: "Haptic Feedback",
                    subtitle: nil,
                    isOn: $hapticFeedback
                )
            }
            .background(cardBackground)
        }
    }

    // MARK: - Advanced Services

    private var advancedSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    showAdvanced.toggle()
                }
            } label: {
                HStack {
                    sectionHeader("REALTIME & PROTOCOL SERVICES")
                    Spacer()
                    Image(systemName: showAdvanced ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(SlipTheme.muted)
                }
            }
            .buttonStyle(.plain)

            if showAdvanced {
                VStack(spacing: 0) {
                    toggleRow(
                        icon: "bell.badge.fill",
                        iconColor: Color(hex: 0xF59E0B),
                        title: "Gate & Turnstile Alerts",
                        subtitle: "Live APNs gate updates",
                        isOn: $gateAlerts
                    )

                    Divider().background(SlipTheme.glassBorder)

                    toggleRow(
                        icon: "rectangle.on.rectangle.angled",
                        iconColor: Color(hex: 0x6366F1),
                        title: "Live Activity & Island",
                        subtitle: "Lock Screen / Dynamic Island HUD",
                        isOn: $liveActivity
                    )

                    Divider().background(SlipTheme.glassBorder)

                    Button {
                        showIdentityVault = true
                    } label: {
                        HStack(spacing: 12) {
                            squircleIcon("person.text.rectangle.fill", color: SlipTheme.accent)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Identity Vault")
                                    .font(SlipTheme.bodyMD())
                                    .fontWeight(.medium)
                                    .foregroundStyle(SlipTheme.ink)
                                Text("Aadhaar / PAN / DL for turnstile checks")
                                    .font(SlipTheme.bodySM())
                                    .foregroundStyle(SlipTheme.muted)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(SlipTheme.muted)
                        }
                        .padding(16)
                    }
                    .buttonStyle(.plain)
                    .sheet(isPresented: $showIdentityVault) {
                        IdentityVaultSheet(store: identityStore)
                    }
                }
                .background(cardBackground)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    // MARK: - Footer

    private var footer: some View {
        VStack(spacing: 14) {
            VStack(spacing: 4) {
                Text("Slip Wallet for iOS • Version 2.4.0 (Build 409)")
                    .font(SlipTheme.labelMono())
                    .foregroundStyle(SlipTheme.muted)
                Text("Encrypted with Apple VAS 2.0 & PassKit Standard")
                    .font(.system(size: 11, weight: .regular, design: .monospaced))
                    .foregroundStyle(SlipTheme.muted.opacity(0.7))
            }

            Button {
                showResetConfirmation = true
            } label: {
                Text("Reset Vault & Sign Out")
                    .font(SlipTheme.bodySM())
                    .fontWeight(.semibold)
                    .foregroundStyle(Color(hex: 0xFF453A))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(Color(hex: 0xFF453A).opacity(0.12))
                            .overlay(Capsule().strokeBorder(Color(hex: 0xFF453A).opacity(0.25), lineWidth: 1))
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 10)
        .padding(.bottom, 24)
    }

    // MARK: - Helpers

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(SlipTheme.labelMono())
            .tracking(1.0)
            .foregroundStyle(SlipTheme.muted)
            .padding(.horizontal, 4)
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(SlipTheme.cardHigh.opacity(0.75))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(SlipTheme.glassBorder, lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.35), radius: 12, y: 6)
    }

    private func squircleIcon(_ systemName: String, color: Color) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(color.opacity(0.2))
                .frame(width: 32, height: 32)
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(color.opacity(0.35), lineWidth: 1)
                )
            Image(systemName: systemName)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(color)
        }
    }

    private func toggleRow(
        icon: String,
        iconColor: Color,
        title: String,
        subtitle: String?,
        isOn: Binding<Bool>
    ) -> some View {
        HStack(spacing: 12) {
            squircleIcon(icon, color: iconColor)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(SlipTheme.bodyMD())
                    .fontWeight(.medium)
                    .foregroundStyle(SlipTheme.ink)
                if let subtitle {
                    Text(subtitle)
                        .font(SlipTheme.bodySM())
                        .foregroundStyle(SlipTheme.muted)
                }
            }

            Spacer(minLength: 8)

            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(SlipTheme.upiGreen)
        }
        .padding(16)
    }

    private func applyPickedAvatar(_ item: PhotosPickerItem) async {
        do {
            if let data = try await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                auth.updateAvatar(image)
            }
        } catch {}
        avatarPickerItem = nil
    }
}
