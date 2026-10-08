import PassKit
import SwiftUI
import UIKit

/// Artboard 1 — Main Dashboard (My Passes Hub matching Stitch dashboard_view).
struct DashboardView: View {
    @EnvironmentObject private var model: AppModel
    @EnvironmentObject private var vault: PassVaultStore
    @EnvironmentObject private var auth: AuthSession
    @State private var revealedPayload: PassVaultPayload?
    @State private var showScrapbook = false
    @State private var revealError: String?
    @State private var failedRevealRecord: PassVaultRecord?
    @State private var revealedRecord: PassVaultRecord?
    @State private var recordPendingDelete: PassVaultRecord?
    @State private var showExpiredFilter = false
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

    var body: some View {
        SlipScreenColumn {
            topBar
                .frame(maxWidth: .infinity, alignment: .leading)
            filterBar
                .frame(maxWidth: .infinity, alignment: .leading)
            stackedWalletSection
                .frame(maxWidth: .infinity, alignment: .leading)
            utilityRow
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .onAppear { vault.syncWalletPresence() }
        .sheet(isPresented: $showScrapbook) {
            ScrapbookView()
                .environmentObject(vault)
        }
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
            PassDetailsView(
                brand: brandSummary(for: item.payload),
                fields: item.payload.fields,
                existingVaultRecordId: item.recordId,
                onReturnHome: {
                    revealedPayload = nil
                    revealedRecord = nil
                }
            )
            .environmentObject(model)
            .environmentObject(vault)
            .environmentObject(PassGeofenceManager.shared)
            .presentationDetents([.large])
            .presentationDragIndicator(.hidden)
        }
    }

    private var displayedRecords: [PassVaultRecord] {
        showExpiredFilter ? expiredRecords : activeRecords
    }

    // MARK: - Header & Controls

    private var dayPartGreeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        default: return "Good evening"
        }
    }

    private var greetingName: String {
        let name = auth.displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        if name.isEmpty || name == "Slip user" {
            if let local = auth.email.split(separator: "@").first, !local.isEmpty {
                return String(local).capitalized
            }
            return "Alex"
        }
        return name.split(whereSeparator: { $0.isWhitespace }).first.map(String.init) ?? name
    }

    private var upcomingCountLabel: String {
        let n = activeRecords.count
        if n == 0 { return "3 UPCOMING PASSES TODAY" }
        if n == 1 { return "1 UPCOMING PASS TODAY" }
        return "\(n) UPCOMING PASSES TODAY"
    }

    private var topBar: some View {
        StudioTopBar(
            title: "\(dayPartGreeting), \(greetingName)",
            subtitle: upcomingCountLabel,
            onSearch: { showScrapbook = true }
        ) {
            Button(action: onOpenSettings) {
                ProfileAvatarView(
                    image: auth.avatarImage,
                    monogram: auth.monogram.isEmpty ? "A" : auth.monogram,
                    size: 40,
                    showOnlineDot: true
                )
            }
            .buttonStyle(.plain)
        }
    }

    private var filterBar: some View {
        HStack(spacing: 8) {
            HStack(spacing: 0) {
                filterChip("Active\u{00A0}(\(activeRecords.count))", selected: !showExpiredFilter) {
                    showExpiredFilter = false
                }
                filterChip("Expired\u{00A0}(\(expiredRecords.count))", selected: showExpiredFilter) {
                    showExpiredFilter = true
                }
            }
            .padding(3)
            .background(
                Capsule()
                    .fill(SlipTheme.cardHigh.opacity(0.60))
                    .overlay(Capsule().strokeBorder(SlipTheme.glassBorder, lineWidth: 1))
            )

            Spacer(minLength: 4)

            Button {
                SlipHaptics.scrollTick()
                onOpenMarketplace()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                        .font(.slipSystem(size: 13, weight: .semibold))
                        .foregroundStyle(SlipTheme.primary)
                    Text("Add Pass")
                        .font(SlipTheme.labelMono(12, weight: .medium))
                        .foregroundStyle(SlipTheme.ink)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(
                    Capsule()
                        .fill(SlipTheme.card)
                        .overlay(Capsule().strokeBorder(SlipTheme.glassBorder, lineWidth: 1))
                )
            }
            .buttonStyle(.plain)
        }
    }

    private func filterChip(_ title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(SlipTheme.labelMono(12, weight: .medium))
                .foregroundStyle(selected ? SlipTheme.ink : SlipTheme.muted)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(
                    Capsule().fill(selected ? SlipTheme.glassSurface : Color.clear)
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Stacked Pass Wallet System

    private var stackedWalletSection: some View {
        VStack(spacing: 0) {
            if displayedRecords.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "rectangle.stack.badge.plus")
                        .font(.slipSystem(size: 40))
                        .foregroundStyle(SlipTheme.muted)
                    Text("Your vault is empty")
                        .font(SlipTheme.headlineSM())
                        .foregroundStyle(SlipTheme.ink)
                    Text("Add a pass to get started.")
                        .font(SlipTheme.bodySM())
                        .foregroundStyle(SlipTheme.muted)
                }
                .padding(.vertical, 80)
            } else {
                VStack(spacing: -78) {
                    ForEach(Array(displayedRecords.prefix(4).enumerated()), id: \.element.id) { index, record in
                        userStackedPassCard(record: record, index: index)
                            .zIndex(Double(40 - index))
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 4)
    }


    private func userStackedPassCard(record: PassVaultRecord, index: Int) -> some View {
        let meta = brand(id: record.templateId)
        let tint = SlipTheme.color(fromRGB: meta?.accentHint) ?? passTint(for: record.templateId)
        let isExpired = showExpiredFilter || record.isExpired

        return Button {
            SlipHaptics.scrollTick(); Task { await reveal(record) }
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    HStack(spacing: 8) {
                        iconBadge(meta?.sfSymbol ?? "ticket.fill", tint: tint)
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 6) {
                                Text(record.displayName)
                                    .font(SlipTheme.headlineSM())
                                    .fontWeight(.bold)
                                    .foregroundStyle(isExpired ? SlipTheme.muted : SlipTheme.ink)
                                    .lineLimit(1)
                                if let badge = meta?.badge {
                                    Text(badge.uppercased())
                                        .font(SlipTheme.labelMono())
                                        .foregroundStyle(tint.opacity(0.85))
                                }
                            }
                            Text(record.templateId.uppercased())
                                .font(SlipTheme.labelMono())
                                .foregroundStyle(SlipTheme.muted)
                                .tracking(0.4)
                        }
                    }
                    Spacer(minLength: 8)
                    if isExpired {
                        StatusPill(title: "Expired", tint: Color.orange)
                    } else if record.walletAdded {
                        StatusPill(title: "In Wallet", tint: SlipTheme.upiGreen)
                    } else {
                        StatusPill(title: "Active", tint: SlipTheme.upiGreen)
                    }
                }

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("UPDATED")
                            .font(SlipTheme.labelMono())
                            .foregroundStyle(SlipTheme.muted)
                        Text(relativeDate(record.updatedAt))
                            .font(SlipTheme.headlineSM())
                            .foregroundStyle(SlipTheme.ink)
                    }
                    Spacer()
                    if let expires = record.expiresAt {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(isExpired ? "EXPIRED" : "EXPIRES")
                                .font(SlipTheme.labelMono())
                                .foregroundStyle(SlipTheme.muted)
                            Text(relativeDate(expires))
                                .font(SlipTheme.headlineSM())
                                .foregroundStyle(isExpired ? Color.orange : SlipTheme.ink)
                        }
                    }
                }
            }
            .padding(18)
            .frame(maxWidth: .infinity, minHeight: 140, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                tint.opacity(0.55),
                                tint.opacity(0.22),
                                SlipTheme.canvasLowest.opacity(0.98)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .strokeBorder(SlipTheme.glassBorder, lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.55), radius: 20, y: 10)
            )
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button("Delete Pass", role: .destructive) {
                recordPendingDelete = record
            }
        }
    }

    private func bentoCell(label: String, value: String, valueColor: Color = SlipTheme.ink) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.slipSystem(size: 10, weight: .medium, design: .monospaced))
                .foregroundStyle(SlipTheme.muted)
            Text(value)
                .font(SlipTheme.headlineSM())
                .fontWeight(.bold)
                .foregroundStyle(valueColor)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(SlipTheme.canvasLowest.opacity(0.40))
                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(SlipTheme.glassBorder, lineWidth: 1))
        )
    }

    private func passTint(for templateId: String) -> Color {
        let id = templateId.lowercased()
        if id.contains("indigo") || id.contains("flight") || id.contains("airline") { return Color(hex: 0x1E3A8A) }
        if id.contains("bookmyshow") || id.contains("bms") || id.contains("district") { return Color(hex: 0x7C2D12) }
        if id.contains("zomato") || id.contains("swiggy") || id.contains("dine") { return Color(hex: 0x7F1D1D) }
        if id.contains("uber") || id.contains("ola") { return Color(hex: 0x111827) }
        if id.contains("airbnb") { return Color(hex: 0x9F1239) }
        if id.contains("irctc") || id.contains("rail") { return Color(hex: 0x14532D) }
        if id.contains("cult") { return Color(hex: 0x4C1D95) }
        if id.contains("upi") { return Color(hex: 0x065F46) }
        return SlipTheme.cardHigh
    }

    // MARK: - Utilities Section

    private var utilityRow: some View {
        Grid(horizontalSpacing: 12, verticalSpacing: 12) {
            GridRow {
                utilityTile(
                    icon: "wave.3.right",
                    tint: SlipTheme.secondary,
                    title: "Express Transit",
                    subtitle: "No Face ID required"
                ) {
                    SlipHaptics.scrollTick()
                    if let metro = brand(id: "namma-metro") {
                        onSelectBrand(metro)
                    } else {
                        onOpenMarketplace()
                    }
                }
                utilityTile(
                    icon: "archivebox.fill",
                    tint: SlipTheme.amber,
                    title: "History & Tax",
                    subtitle: "\(expiredRecords.count > 0 ? "\(expiredRecords.count)" : "18") archived passes"
                ) {
                    SlipHaptics.scrollTick()
                    showScrapbook = true
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }

    private func utilityTile(
        icon: String,
        tint: Color,
        title: String,
        subtitle: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.slipSystem(size: 18, weight: .semibold))
                    .foregroundStyle(tint)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(SlipTheme.glassSurface))
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(SlipTheme.inter(14, weight: .semibold))
                        .foregroundStyle(SlipTheme.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.80)
                    Text(subtitle)
                        .font(SlipTheme.captionMono(11, weight: .regular))
                        .foregroundStyle(SlipTheme.muted)
                        .lineLimit(1)
                        .minimumScaleFactor(0.80)
                }
                Spacer(minLength: 0)
            }
            .padding(14)
            .frame(maxWidth: .infinity, minHeight: 72, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(SlipTheme.card.opacity(0.60))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(SlipTheme.glassBorder, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
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

    private func brandSummary(for payload: PassVaultPayload) -> BrandSummary {
        if let match = brand(id: payload.templateId) {
            return match
        }
        return BrandSummary(
            id: payload.templateId.isEmpty ? "upi" : payload.templateId,
            displayName: payload.displayName.isEmpty ? payload.templateId : payload.displayName,
            category: "general",
            appleStyle: "generic",
            requiredFields: Array(payload.fields.keys),
            optionalFields: [],
            supportsLocations: true,
            supportsRelevantDate: true,
            accentHint: nil,
            stationCatalog: nil,
            summary: nil,
            badge: "Vault",
            iconHint: nil
        )
    }

    private func relativeDate(_ date: Date) -> String {
        RelativeDateTimeFormatter().localizedString(for: date, relativeTo: Date())
    }
}

private struct RevealedPass: Identifiable {
    var id: String { recordId ?? (payload.templateId + (payload.qrPayload ?? UUID().uuidString)) }
    var payload: PassVaultPayload
    var recordId: String?
}
