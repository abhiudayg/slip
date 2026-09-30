import PassKit
import SwiftUI
import UIKit

/// Artboard 1 — Main Dashboard (My Passes Hub)
struct DashboardView: View {
    @EnvironmentObject private var model: AppModel
    @EnvironmentObject private var vault: PassVaultStore
    @EnvironmentObject private var auth: AuthSession
    @State private var revealedPayload: PassVaultPayload?
    @State private var revealError: String?
    @State private var failedRevealRecord: PassVaultRecord?
    @State private var revealedRecord: PassVaultRecord?
    @State private var recordPendingDelete: PassVaultRecord?
    var onOpenSettings: () -> Void
    var onOpenMarketplace: () -> Void
    var onSelectBrand: (BrandSummary) -> Void

    private var catalog: [BrandSummary] {
        model.brands.isEmpty ? BrandSummary.fallbackCatalog : model.brands
    }

    private var activeRecords: [PassVaultRecord] {
        vault.records.filter { !$0.isExpired }.sorted { $0.updatedAt > $1.updatedAt }
    }

    private var expiredRecords: [PassVaultRecord] {
        vault.records.filter(\.isExpired).sorted { ($0.expiresAt ?? $0.updatedAt) > ($1.expiresAt ?? $1.updatedAt) }
    }

    private var transitRecords: [PassVaultRecord] {
        activeRecords.filter { record in
            catalog.first(where: { $0.id == record.templateId })?.category == "transit"
                || record.templateId.contains("metro")
                || record.templateId.contains("transit")
        }
    }

    private var upiRecords: [PassVaultRecord] {
        activeRecords.filter { $0.templateId == "upi" }
    }

    private var recentRecords: [PassVaultRecord] {
        activeRecords
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 22) {
                topBar
                heroHeader
                vaultPassesSection
                if !expiredRecords.isEmpty {
                    expiredPassesSection
                }
                featuredTransitSection
                allPassesSection
                upiSection
                recentActivitySection
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 120)
        }
        .onAppear { vault.syncWalletPresence() }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("PKPassLibraryDidChangeNotification"))) { _ in
            vault.syncWalletPresence()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            vault.syncWalletPresence()
        }
        .alert("Vault", isPresented: Binding(
            get: { revealError != nil },
            set: { if !$0 { revealError = nil; failedRevealRecord = nil } }
        )) {
            if failedRevealRecord != nil {
                Button("Delete unreadable pass", role: .destructive) {
                    if let record = failedRevealRecord {
                        try? vault.delete(record)
                    }
                    failedRevealRecord = nil
                    revealError = nil
                }
            }
            Button("OK", role: .cancel) {
                failedRevealRecord = nil
            }
        } message: {
            Text(revealError ?? "")
        }
        .confirmationDialog(
            "Delete pass?",
            isPresented: Binding(
                get: { recordPendingDelete != nil },
                set: { if !$0 { recordPendingDelete = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let record = recordPendingDelete {
                    try? vault.delete(record)
                    if revealedRecord?.id == record.id {
                        revealedPayload = nil
                        revealedRecord = nil
                    }
                }
                recordPendingDelete = nil
            }
            Button("Cancel", role: .cancel) {
                recordPendingDelete = nil
            }
        } message: {
            Text("Removes \"\(recordPendingDelete?.displayName ?? "this pass")\" from the encrypted vault. This cannot be undone.")
        }
        .sheet(item: Binding(
            get: { revealedPayload.map { RevealedPass(payload: $0, recordId: revealedRecord?.id) } },
            set: { newValue in
                revealedPayload = newValue?.payload
                if newValue == nil { revealedRecord = nil }
            }
        )) { item in
            NavigationStack {
                List {
                    LabeledContent("Brand", value: item.payload.displayName)
                    LabeledContent("Template", value: item.payload.templateId)
                    ForEach(BrandFields.schema(for: item.payload.templateId).all, id: \.self) { key in
                        let value = item.payload.fields[key] ?? ""
                        if !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            LabeledContent(key.replacingOccurrences(of: "_", with: " ").capitalized, value: value)
                        }
                    }
                }
                .navigationTitle("Secure Pass")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Lock") {
                            revealedPayload = nil
                            revealedRecord = nil
                            vault.lock()
                        }
                    }
                    ToolbarItem(placement: .destructiveAction) {
                        Button("Delete", role: .destructive) {
                            if let record = revealedRecord {
                                revealedPayload = nil
                                revealedRecord = nil
                                DispatchQueue.main.async {
                                    recordPendingDelete = record
                                }
                            }
                        }
                    }
                }
            }
            .presentationDetents([.medium, .large])
        }
    }

    private var vaultPassesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Active Passes")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(SlipTheme.ink)
                Text("\(activeRecords.count)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(SlipTheme.muted)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(Color.white.opacity(0.08)))
                Spacer()
                Label(vault.isUnlocked ? "Unlocked" : "Locked", systemImage: vault.isUnlocked ? "lock.open.fill" : "lock.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(SlipTheme.accentSoft)
            }

            if activeRecords.isEmpty {
                GlassCard(cornerRadius: 18, padding: 14) {
                    Text(vault.records.isEmpty
                         ? "Passes you generate are sealed with AES-256-GCM and sync as ciphertext via iCloud."
                         : "No active passes — expired ones are listed below.")
                        .font(.caption)
                        .foregroundStyle(SlipTheme.muted)
                }
            } else {
                ForEach(activeRecords, id: \.id) { record in
                    vaultRow(record, expired: false)
                }
            }
        }
    }

    private var expiredPassesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Expired Passes")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(SlipTheme.ink)
                Text("\(expiredRecords.count)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(SlipTheme.muted)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(Color.white.opacity(0.08)))
                Spacer()
            }

            ForEach(expiredRecords, id: \.id) { record in
                vaultRow(record, expired: true)
            }
        }
    }

    private func vaultRow(_ record: PassVaultRecord, expired: Bool) -> some View {
        HStack(spacing: 10) {
            Button {
                Task { await reveal(record) }
            } label: {
                GlassCard(cornerRadius: 18, padding: 14) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(record.displayName)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(expired ? SlipTheme.muted : SlipTheme.ink)
                            Text(record.templateId)
                                .font(.caption)
                                .foregroundStyle(SlipTheme.muted)
                            if let expires = record.expiresAt {
                                Text(expired
                                     ? "Expired \(relativeDate(expires))"
                                     : "Expires \(relativeDate(expires))")
                                    .font(.caption2)
                                    .foregroundStyle(expired ? Color.orange.opacity(0.9) : SlipTheme.accentSoft)
                            }
                        }
                        Spacer()
                        if expired && record.walletAdded {
                            StatusPill(title: "Expired · Wallet", tint: Color.orange)
                        } else if expired {
                            StatusPill(title: "Expired", tint: Color.orange)
                        } else if record.walletAdded {
                            StatusPill(title: "In Wallet", tint: SlipTheme.upiGreen)
                        }
                        Image(systemName: expired ? "clock.badge.xmark" : "lock.shield.fill")
                            .foregroundStyle(expired ? Color.orange.opacity(0.8) : SlipTheme.accentSoft)
                    }
                }
                .opacity(expired ? 0.85 : 1)
            }
            .buttonStyle(.plain)

            Button(role: .destructive) {
                recordPendingDelete = record
            } label: {
                Image(systemName: "trash")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(Color(hex: 0x93000A).opacity(0.9)))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Delete pass")
        }
        .contextMenu {
            Button("Delete Pass", role: .destructive) {
                recordPendingDelete = record
            }
        }
    }

    private func reveal(_ record: PassVaultRecord) async {
        if !vault.isUnlocked {
            let unlocked = await vault.unlock()
            guard unlocked else {
                revealError = "Authentication required to decrypt pass data."
                failedRevealRecord = nil
                return
            }
        }
        do {
            revealedPayload = try vault.decrypt(record)
            revealedRecord = record
            failedRevealRecord = nil
        } catch {
            revealedRecord = nil
            failedRevealRecord = record
            revealError = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    private var topBar: some View {
        StudioTopBar(title: "Slip Studio", onSearch: onOpenMarketplace) {
            Button(action: onOpenSettings) {
                ProfileAvatarView(
                    image: auth.avatarImage,
                    monogram: auth.monogram,
                    size: 32
                )
            }
            .buttonStyle(.plain)
        }
    }

    private var heroHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center, spacing: 10) {
                Text("Slip")
                    .font(.system(size: 34, weight: .bold))
                    .tracking(-0.85)
                    .foregroundStyle(SlipTheme.ink)
                StatusPill(
                    title: syncStatusTitle,
                    tint: syncStatusTint,
                    systemImage: syncStatusImage
                )
                Spacer(minLength: 0)
            }
            Text(heroSubtitle)
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(SlipTheme.muted)
            Text("Ready On Lock Screen")
                .font(.system(size: 11, weight: .semibold))
                .tracking(1.2)
                .textCase(.uppercase)
                .foregroundStyle(SlipTheme.secondary)
                .padding(.top, 2)
        }
    }

    private var syncStatusTitle: String {
        if model.isLoadingBrands { return "Syncing" }
        if model.errorMessage != nil && model.brands.isEmpty { return "Offline" }
        return "Synced"
    }

    private var syncStatusTint: Color {
        if model.isLoadingBrands { return SlipTheme.amber }
        if model.errorMessage != nil && model.brands.isEmpty { return SlipTheme.magenta }
        return SlipTheme.accentSoft
    }

    private var syncStatusImage: String? {
        if model.isLoadingBrands { return "arrow.triangle.2.circlepath" }
        if model.errorMessage != nil && model.brands.isEmpty { return "icloud.slash" }
        return "checkmark.icloud.fill"
    }

    private var heroSubtitle: String {
        if model.errorMessage != nil && model.brands.isEmpty {
            return "Couldn't reach pass-engine — showing offline catalog."
        }
        return "Urban Transit & Identity Credentials"
    }

    @ViewBuilder
    private var featuredTransitSection: some View {
        if let record = transitRecords.first {
            featuredTransitCard(record: record)
        } else if let metro = brand(id: "namma-metro") {
            GlassCard(cornerRadius: 28, padding: 18) {
                VStack(alignment: .leading, spacing: 14) {
                    HStack(alignment: .top, spacing: 12) {
                        iconBadge(metro.sfSymbol, tint: SlipTheme.indigo)
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 8) {
                                Text(metro.displayName)
                                    .font(.headline)
                                    .foregroundStyle(SlipTheme.ink)
                                Text("PURPLE LINE")
                                    .font(.system(size: 10, weight: .bold))
                                    .tracking(0.6)
                                    .foregroundStyle(SlipTheme.accentSoft)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Capsule().fill(SlipTheme.accent.opacity(0.28)))
                            }
                            Text(metro.summary ?? "WhatsApp QR to Dynamic Lock Screen ticket.")
                                .font(.caption)
                                .foregroundStyle(SlipTheme.muted)
                        }
                        Spacer()
                        Button {
                            onSelectBrand(metro)
                        } label: {
                            Text("Add")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(Capsule().fill(SlipTheme.accent))
                        }
                        .buttonStyle(.plain)
                    }
                    HStack(spacing: 8) {
                        Image(systemName: "wave.3.right")
                            .foregroundStyle(SlipTheme.accentSoft)
                        Text("Turnstile Tap")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(SlipTheme.ink)
                        Spacer()
                        Text("Double-click side button to open")
                            .font(.caption)
                            .foregroundStyle(SlipTheme.muted)
                    }
                }
            }
        } else {
            EmptyView()
        }
    }

    private func featuredTransitCard(record: PassVaultRecord) -> some View {
        let brandMeta = brand(id: record.templateId)
        let tint = SlipTheme.color(fromRGB: brandMeta?.accentHint) ?? SlipTheme.indigo
        return GlassCard(cornerRadius: 28, padding: 18) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top) {
                    HStack(spacing: 10) {
                        iconBadge(brandMeta?.sfSymbol ?? "tram.fill", tint: tint)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(record.displayName)
                                .font(.headline)
                                .foregroundStyle(SlipTheme.ink)
                            Text(vault.isUnlocked ? "Tap to reveal route fields" : "Encrypted · unlock to view details")
                                .font(.caption)
                                .foregroundStyle(SlipTheme.muted)
                        }
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 6) {
                        Text((brandMeta?.badge ?? "TRANSIT").uppercased())
                            .font(.system(size: 10, weight: .bold))
                            .tracking(0.8)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(tint))
                        Text(record.updatedAt, style: .relative)
                            .font(.caption2)
                            .foregroundStyle(SlipTheme.muted)
                    }
                }

                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Image(systemName: "wave.3.right")
                                .foregroundStyle(SlipTheme.accentSoft)
                            Text(walletStatusLabel(record))
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(SlipTheme.ink)
                        }
                        Text("Double-click side button to open")
                            .font(.caption)
                            .foregroundStyle(SlipTheme.muted)
                    }
                    Spacer()
                    Button {
                        Task { await reveal(record) }
                    } label: {
                        Image(systemName: "arrow.up.left.and.arrow.down.right")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.white)
                            .frame(width: 52, height: 52)
                            .background(Circle().fill(SlipTheme.accent).shadow(color: SlipTheme.accent.opacity(0.45), radius: 10, y: 4))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .contextMenu {
            Button("Delete Pass", role: .destructive) {
                recordPendingDelete = record
            }
        }
        .overlay(alignment: .top) {
            LinearGradient(
                colors: [tint.opacity(0.55), .clear],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 28)
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .allowsHitTesting(false)
        }
    }

    private var allPassesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(vault.records.isEmpty ? "Templates" : "All Passes")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(SlipTheme.ink)
                Text(vault.records.isEmpty ? "\(catalog.count) Available" : "\(vault.records.count) Passes")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(SlipTheme.muted)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(Color.white.opacity(0.08)))
                Spacer()
                Button(vault.records.isEmpty ? "Browse" : "Add") {
                    onOpenMarketplace()
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(SlipTheme.muted)
            }

            if vault.records.isEmpty {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(catalog.prefix(4)) { brand in
                        passMiniCard(
                            title: brand.displayName.uppercased(),
                            subtitle: brand.badge ?? brand.categoryTitle,
                            badge: brand.appleStyle,
                            badgeTint: SlipTheme.color(fromRGB: brand.accentHint) ?? SlipTheme.accent,
                            meta: brand.summary ?? "From pass-engine",
                            icon: brand.sfSymbol,
                            glow: SlipTheme.color(fromRGB: brand.accentHint) ?? SlipTheme.accent
                        ) {
                            onSelectBrand(brand)
                        }
                    }
                }
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(activeRecords, id: \.id) { record in
                        let meta = brand(id: record.templateId)
                        let glow = SlipTheme.color(fromRGB: meta?.accentHint) ?? SlipTheme.accent
                        passMiniCard(
                            title: record.displayName.uppercased(),
                            subtitle: meta?.badge ?? record.templateId,
                            badge: vaultStatusBadge(record).title,
                            badgeTint: vaultStatusBadge(record).tint,
                            meta: relativeDate(record.updatedAt),
                            icon: meta?.sfSymbol ?? "lock.shield.fill",
                            glow: glow,
                            onDelete: { recordPendingDelete = record }
                        ) {
                            Task { await reveal(record) }
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var upiSection: some View {
        if let record = upiRecords.first {
            GlassCard(cornerRadius: 22, padding: 16) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Label(record.displayName, systemImage: "qrcode")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(SlipTheme.ink)
                        Text("VAULT")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(SlipTheme.indigo))
                        Spacer()
                        Text(walletStatusLabel(record))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(SlipTheme.accentSoft)
                    }
                    Text("Encrypted UPI pass — unlock to view QR payload.")
                        .font(.caption)
                        .foregroundStyle(SlipTheme.muted)

                    Button {
                        Task { await reveal(record) }
                    } label: {
                        HStack {
                            Image(systemName: "lock.shield.fill")
                                .foregroundStyle(SlipTheme.ink)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(record.displayName)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(SlipTheme.ink)
                                Text("Tap to authenticate & reveal")
                                    .font(.caption2)
                                    .foregroundStyle(SlipTheme.muted)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(SlipTheme.muted)
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color.black.opacity(0.35))
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .contextMenu {
                Button("Delete Pass", role: .destructive) {
                    recordPendingDelete = record
                }
            }
        } else if let upi = brand(id: "upi") {
            GlassCard(cornerRadius: 22, padding: 16) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Label(upi.displayName, systemImage: upi.sfSymbol)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(SlipTheme.ink)
                        Text(upi.badge ?? "UPI")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(SlipTheme.indigo))
                        Spacer()
                    }
                    Text(upi.summary ?? "Create a personal UPI receive QR pass.")
                        .font(.caption)
                        .foregroundStyle(SlipTheme.muted)
                    Button {
                        onSelectBrand(upi)
                    } label: {
                        Text("Create UPI pass")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(RoundedRectangle(cornerRadius: 14).fill(SlipTheme.upiGreen.opacity(0.85)))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    @ViewBuilder
    private var recentActivitySection: some View {
        if let latest = recentRecords.first {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Recent Vault Activity")
                        .font(.caption.weight(.semibold))
                        .tracking(0.8)
                        .textCase(.uppercase)
                        .foregroundStyle(SlipTheme.muted)
                    Spacer()
                    Button("Browse templates", action: onOpenMarketplace)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(SlipTheme.accentSoft)
                }
                Button {
                    Task { await reveal(latest) }
                } label: {
                    GlassCard(cornerRadius: 18, padding: 14) {
                        HStack(spacing: 12) {
                            let meta = brand(id: latest.templateId)
                            iconBadge(meta?.sfSymbol ?? "clock.fill", tint: SlipTheme.color(fromRGB: meta?.accentHint) ?? SlipTheme.amber)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(latest.displayName)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(SlipTheme.ink)
                                Text("Updated \(relativeDate(latest.updatedAt))")
                                    .font(.caption)
                                    .foregroundStyle(SlipTheme.muted)
                            }
                            Spacer()
                            Image(systemName: "lock.shield.fill")
                                .foregroundStyle(SlipTheme.muted)
                        }
                    }
                }
                .buttonStyle(.plain)
                .contextMenu {
                    Button("Delete Pass", role: .destructive) {
                        recordPendingDelete = latest
                    }
                }
            }
        }
    }

    private func passMiniCard(
        title: String,
        subtitle: String,
        badge: String,
        badgeTint: Color,
        meta: String,
        icon: String,
        glow: Color,
        status: String? = nil,
        onDelete: (() -> Void)? = nil,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: icon)
                        .foregroundStyle(glow)
                    Spacer()
                    Text(badge.uppercased())
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(badgeTint))
                }
                Text(title)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(SlipTheme.ink)
                    .lineLimit(2)
                Text(subtitle)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(SlipTheme.muted)
                Text(meta)
                    .font(.caption2)
                    .foregroundStyle(SlipTheme.muted)
                    .lineLimit(2)
                if let status {
                    Text(status)
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.85))
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, minHeight: 160, alignment: .topLeading)
            .background {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .fill(glow.opacity(0.12))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.14), lineWidth: 1)
                    )
            }
        }
        .buttonStyle(.plain)
        .overlay(alignment: .topTrailing) {
            if let onDelete {
                Button(role: .destructive, action: onDelete) {
                    Image(systemName: "trash.circle.fill")
                        .font(.title2)
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.white, Color(hex: 0x93000A))
                }
                .buttonStyle(.plain)
                .padding(8)
                .accessibilityLabel("Delete pass")
            }
        }
        .contextMenu {
            if let onDelete {
                Button("Delete Pass", role: .destructive, action: onDelete)
            }
        }
    }

    private func iconBadge(_ systemName: String, tint: Color) -> some View {
        Image(systemName: systemName)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.white)
            .frame(width: 36, height: 36)
            .background(Circle().fill(tint))
    }

    private func brand(id: String) -> BrandSummary? {
        catalog.first { $0.id == id }
    }

    private func relativeDate(_ date: Date) -> String {
        RelativeDateTimeFormatter().localizedString(for: date, relativeTo: Date())
    }

    private func vaultStatusBadge(_ record: PassVaultRecord) -> (title: String, tint: Color) {
        if record.isExpired && record.walletAdded {
            return ("EXPIRED · WALLET", Color.orange)
        }
        if record.isExpired {
            return ("EXPIRED", Color.orange)
        }
        if record.walletAdded {
            return ("WALLET", SlipTheme.upiGreen)
        }
        return ("VAULT", SlipTheme.indigo)
    }

    private func walletStatusLabel(_ record: PassVaultRecord) -> String {
        if record.isExpired && record.walletAdded {
            return "Expired · still in Wallet"
        }
        if record.isExpired {
            return "Expired"
        }
        if record.walletAdded {
            return "In Apple Wallet"
        }
        return "Sealed"
    }
}

private struct RevealedPass: Identifiable {
    var id: String { recordId ?? (payload.templateId + (payload.qrPayload ?? UUID().uuidString)) }
    var payload: PassVaultPayload
    var recordId: String?
}
