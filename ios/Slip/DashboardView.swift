import SwiftUI

/// Artboard 1 — Main Dashboard (My Passes Hub)
struct DashboardView: View {
    @EnvironmentObject private var model: AppModel
    @EnvironmentObject private var vault: PassVaultStore
    @State private var revealedPayload: PassVaultPayload?
    @State private var revealError: String?
    var onOpenSettings: () -> Void
    var onOpenMarketplace: () -> Void
    var onSelectBrand: (BrandSummary) -> Void

    private var catalog: [BrandSummary] {
        model.brands.isEmpty ? BrandSummary.fallbackCatalog : model.brands
    }

    private var transitRecords: [PassVaultRecord] {
        vault.records.filter { record in
            catalog.first(where: { $0.id == record.templateId })?.category == "transit"
                || record.templateId.contains("metro")
                || record.templateId.contains("transit")
        }
        .sorted { $0.updatedAt > $1.updatedAt }
    }

    private var upiRecords: [PassVaultRecord] {
        vault.records.filter { $0.templateId == "upi" }
            .sorted { $0.updatedAt > $1.updatedAt }
    }

    private var recentRecords: [PassVaultRecord] {
        vault.records.sorted { $0.updatedAt > $1.updatedAt }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 22) {
                topBar
                heroHeader
                vaultPassesSection
                featuredTransitSection
                allPassesSection
                upiSection
                recentActivitySection
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 120)
        }
        .alert("Vault", isPresented: Binding(
            get: { revealError != nil },
            set: { if !$0 { revealError = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(revealError ?? "")
        }
        .sheet(item: Binding(
            get: { revealedPayload.map { RevealedPass(payload: $0) } },
            set: { revealedPayload = $0?.payload }
        )) { item in
            NavigationStack {
                List {
                    LabeledContent("Brand", value: item.payload.displayName)
                    LabeledContent("Template", value: item.payload.templateId)
                    ForEach(item.payload.fields.keys.sorted(), id: \.self) { key in
                        LabeledContent(key, value: item.payload.fields[key] ?? "")
                    }
                }
                .navigationTitle("Secure Pass")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Lock") {
                            revealedPayload = nil
                            vault.lock()
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
                Text("Encrypted Vault")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(SlipTheme.ink)
                Text("\(vault.records.count)")
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

            if vault.records.isEmpty {
                GlassCard(cornerRadius: 18, padding: 14) {
                    Text("Passes you confirm are sealed with AES-256-GCM and sync as ciphertext via iCloud.")
                        .font(.caption)
                        .foregroundStyle(SlipTheme.muted)
                }
            } else {
                ForEach(vault.records, id: \.id) { record in
                    Button {
                        Task { await reveal(record) }
                    } label: {
                        GlassCard(cornerRadius: 18, padding: 14) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(record.displayName)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(SlipTheme.ink)
                                    Text(record.templateId)
                                        .font(.caption)
                                        .foregroundStyle(SlipTheme.muted)
                                }
                                Spacer()
                                if record.walletAdded {
                                    StatusPill(title: "In Wallet", tint: SlipTheme.upiGreen)
                                }
                                Image(systemName: "lock.shield.fill")
                                    .foregroundStyle(SlipTheme.accentSoft)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func reveal(_ record: PassVaultRecord) async {
        if !vault.isUnlocked {
            let unlocked = await vault.unlock()
            guard unlocked else {
                revealError = "Authentication required to decrypt pass data."
                return
            }
        }
        do {
            revealedPayload = try vault.decrypt(record)
        } catch {
            revealError = error.localizedDescription
        }
    }

    private var topBar: some View {
        HStack {
            HStack(spacing: 8) {
                SlipBrandMark(size: 28)
                Text("Slip")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(SlipTheme.ink)
            }
            Spacer()
            Button(action: onOpenMarketplace) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(SlipTheme.muted)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(Color.white.opacity(0.06)))
            }
            Button(action: onOpenSettings) {
                Image(systemName: "person.crop.circle.fill")
                    .font(.title2)
                    .foregroundStyle(SlipTheme.indigo)
                    .overlay(alignment: .bottomTrailing) {
                        Circle()
                            .fill(SlipTheme.accent)
                            .frame(width: 10, height: 10)
                            .overlay(Circle().stroke(SlipTheme.canvas, lineWidth: 2))
                    }
            }
        }
    }

    private var heroHeader: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text("Slip")
                    .font(.system(size: 34, weight: .bold))
                    .tracking(-0.6)
                    .foregroundStyle(SlipTheme.ink)
                StatusPill(title: syncStatusTitle, tint: syncStatusTint)
                Spacer()
            }
            Text(heroSubtitle)
                .font(.subheadline)
                .foregroundStyle(SlipTheme.muted)
            HStack {
                StatusPill(
                    title: vault.records.isEmpty ? "No passes yet" : "\(vault.records.count) sealed",
                    tint: SlipTheme.accentSoft
                )
                Spacer()
                if model.isLoadingBrands {
                    ProgressView()
                        .tint(SlipTheme.accentSoft)
                } else {
                    Label("\(catalog.count) templates", systemImage: "square.stack.3d.up.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(SlipTheme.accentSoft)
                }
            }
        }
    }

    private var syncStatusTitle: String {
        if model.isLoadingBrands { return "Syncing" }
        if model.errorMessage != nil && model.brands.isEmpty { return "Offline" }
        return "Live"
    }

    private var syncStatusTint: Color {
        if model.isLoadingBrands { return SlipTheme.amber }
        if model.errorMessage != nil && model.brands.isEmpty { return SlipTheme.magenta }
        return SlipTheme.upiGreen
    }

    private var heroSubtitle: String {
        if let err = model.errorMessage, model.brands.isEmpty {
            return "Couldn't reach pass-engine — showing offline catalog. \(err)"
        }
        if vault.records.isEmpty {
            return "Scan a ticket or pick a template from the marketplace."
        }
        return "Your passes are encrypted on-device and synced as ciphertext via iCloud."
    }

    @ViewBuilder
    private var featuredTransitSection: some View {
        if let record = transitRecords.first {
            featuredTransitCard(record: record)
        } else if let metro = brand(id: "namma-metro") {
            GlassCard(cornerRadius: 28, padding: 18) {
                HStack(alignment: .top, spacing: 12) {
                    iconBadge(metro.sfSymbol, tint: SlipTheme.indigo)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(metro.displayName)
                            .font(.headline)
                            .foregroundStyle(SlipTheme.ink)
                        Text(metro.summary ?? "Add a metro ticket from a QR screenshot.")
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
            }
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
                        Label(record.walletAdded ? "In Apple Wallet" : "Ready to add", systemImage: "wave.3.right")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(SlipTheme.ink)
                        Text("Double-click side button after Wallet add")
                            .font(.caption)
                            .foregroundStyle(SlipTheme.muted)
                    }
                    Spacer()
                    Button {
                        Task { await reveal(record) }
                    } label: {
                        Image(systemName: "lock.open.fill")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.white)
                            .frame(width: 52, height: 52)
                            .background(Circle().fill(SlipTheme.accent))
                    }
                    .buttonStyle(.plain)
                }
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
                    ForEach(vault.records, id: \.id) { record in
                        let meta = brand(id: record.templateId)
                        let glow = SlipTheme.color(fromRGB: meta?.accentHint) ?? SlipTheme.accent
                        passMiniCard(
                            title: record.displayName.uppercased(),
                            subtitle: meta?.badge ?? record.templateId,
                            badge: record.walletAdded ? "WALLET" : "VAULT",
                            badgeTint: record.walletAdded ? SlipTheme.upiGreen : glow,
                            meta: relativeDate(record.updatedAt),
                            icon: meta?.sfSymbol ?? "lock.shield.fill",
                            glow: glow
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
                        Text(record.walletAdded ? "In Wallet" : "Sealed")
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
}

private struct RevealedPass: Identifiable {
    var id: String { payload.templateId + (payload.qrPayload ?? UUID().uuidString) }
    var payload: PassVaultPayload
}
