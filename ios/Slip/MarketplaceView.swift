import PhotosUI
import SwiftUI

/// Artboard — Marketplace / Discover (Stitch `marketplace_discover_passes`).
struct MarketplaceView: View {
    @EnvironmentObject private var model: AppModel
    @State private var query = ""
    @State private var selectedCategory = "All"
    @State private var showDetectedBanner = true
    var onClose: (() -> Void)? = nil
    var onSelectBrand: (BrandSummary) -> Void
    var onScanScreenshot: () -> Void
    var onImportPDF: (() -> Void)? = nil

    private let categories = [
        "All",
        "Transit & Flights",
        "Cinema & Events",
        "Dining & Nightlife",
        "Keys & Mobility",
        "Fintech & UPI"
    ]

    var body: some View {
        SlipScreenColumn {
            header.frame(maxWidth: .infinity, alignment: .leading)

            if showDetectedBanner {
                detectedPassesToast
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }

            searchAndFilterBar.frame(maxWidth: .infinity, alignment: .leading)
            categoryChips.frame(maxWidth: .infinity, alignment: .leading)
            actionCards.frame(maxWidth: .infinity, alignment: .leading)
            brandsHeader.frame(maxWidth: .infinity, alignment: .leading)
            templateList.frame(maxWidth: .infinity, alignment: .leading)

            if filteredBrands.isEmpty {
                emptyState.frame(maxWidth: .infinity, alignment: .leading)
            }

            customPassPromoBanner.frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                HStack(spacing: 6) {
                    Circle()
                        .fill(SlipTheme.upiGreen)
                        .frame(width: 6, height: 6)
                    Text("CATALOG V2.4")
                        .font(SlipTheme.labelMono())
                        .tracking(1.0)
                        .foregroundStyle(SlipTheme.inkVariant)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(
                    Capsule()
                        .fill(SlipTheme.glassSurface)
                        .overlay(Capsule().strokeBorder(SlipTheme.glassBorder, lineWidth: 1))
                )

                Spacer()

                if let onClose {
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .font(.slipSystem(size: 14, weight: .semibold))
                            .foregroundStyle(SlipTheme.ink)
                            .frame(width: 36, height: 36)
                            .background(Circle().fill(SlipTheme.card.opacity(0.7)))
                            .overlay(Circle().strokeBorder(SlipTheme.glassBorder, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                } else {
                    Button {
                        // Notifications / activity sheet
                    } label: {
                        Image(systemName: "bell.fill")
                            .font(.slipSystem(size: 16, weight: .semibold))
                            .foregroundStyle(SlipTheme.ink)
                            .frame(width: 40, height: 40)
                            .background(Circle().fill(SlipTheme.card.opacity(0.7)))
                            .overlay(Circle().strokeBorder(SlipTheme.glassBorder, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Marketplace")
                    .font(SlipTheme.headlineXL())
                    .tracking(-0.6)
                    .foregroundStyle(SlipTheme.ink)
                Text("Supported brands & one-tap templates")
                    .font(SlipTheme.bodyMD())
                    .foregroundStyle(SlipTheme.muted)
            }
        }
    }

    // MARK: - Smart Alert Toast

    private var detectedPassesToast: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(SlipTheme.meshTeal.opacity(0.8))
                    .frame(width: 36, height: 36)
                Image(systemName: "envelope.badge.fill")
                    .font(.slipSystem(size: 16, weight: .semibold))
                    .foregroundStyle(Color(hex: 0x5EEAD4))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("2 Pass Emails Detected")
                    .font(SlipTheme.headlineSM())
                    .foregroundStyle(SlipTheme.ink)
                Text("IndiGo 6E-241 & BookMyShow tickets")
                    .font(.slipSystem(size: 11, weight: .regular))
                    .foregroundStyle(SlipTheme.muted)
            }

            Spacer(minLength: 4)

            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    showDetectedBanner = false
                }
                onScanScreenshot()
            } label: {
                Text("Import")
                    .font(SlipTheme.labelMono())
                    .foregroundStyle(SlipTheme.ink)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(
                        Capsule()
                            .fill(SlipTheme.glassSurface)
                            .overlay(Capsule().strokeBorder(SlipTheme.glassBorder, lineWidth: 1))
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(SlipTheme.cardHigh.opacity(0.85))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(SlipTheme.glassBorder, lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.3), radius: 10, y: 4)
    }

    // MARK: - Search & Filter Bar

    private var searchAndFilterBar: some View {
        HStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(SlipTheme.muted)
                TextField("Search brands, transit, movies...", text: $query)
                    .font(SlipTheme.bodySM())
                    .foregroundStyle(SlipTheme.ink)
                    .textInputAutocapitalization(.never)
                if !query.isEmpty {
                    Button {
                        query = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.slipSystem(size: 14))
                            .foregroundStyle(SlipTheme.muted)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(SlipTheme.cardHigh.opacity(0.55))
                    .overlay(Capsule().strokeBorder(SlipTheme.glassBorder, lineWidth: 1))
            )

            Button {
                // Filter action
            } label: {
                Image(systemName: "slider.horizontal.3")
                    .font(.slipSystem(size: 16, weight: .semibold))
                    .foregroundStyle(SlipTheme.ink)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(SlipTheme.cardHigh.opacity(0.55))
                            .overlay(Circle().strokeBorder(SlipTheme.glassBorder, lineWidth: 1))
                    )
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Hero Action Cards

    private var actionCards: some View {
        Grid(horizontalSpacing: 12, verticalSpacing: 12) {
            GridRow {
                Button(action: onScanScreenshot) {
                    actionCard(
                        icon: "viewfinder",
                        title: "Scan Image",
                        subtitle: "Extract pass from screenshots or gallery",
                        cta: "OCR Auto-fill",
                        glow: SlipTheme.primary.opacity(0.12)
                    )
                }
                .buttonStyle(.plain)

                Button {
                    onImportPDF?()
                } label: {
                    actionCard(
                        icon: "doc.text.fill",
                        title: "Import PDF",
                        subtitle: "Instant boarding passes, ticket PDFs & invoices",
                        cta: "Choose file",
                        glow: Color(hex: 0x6366F1).opacity(0.12)
                    )
                }
                .buttonStyle(.plain)
                .disabled(onImportPDF == nil)
                .opacity(onImportPDF == nil ? 0.55 : 1)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func actionCard(
        icon: String,
        title: String,
        subtitle: String,
        cta: String,
        glow: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon)
                .font(.slipSystem(size: 18, weight: .semibold))
                .foregroundStyle(SlipTheme.ink)
                .frame(width: 40, height: 40)
                .background(
                    Circle()
                        .fill(SlipTheme.glassSurface)
                        .overlay(Circle().strokeBorder(SlipTheme.glassBorder, lineWidth: 1))
                )

            Text(title)
                .font(SlipTheme.headlineSM())
                .foregroundStyle(SlipTheme.ink)
            Text(subtitle)
                .font(.slipSystem(size: 12, weight: .regular))
                .foregroundStyle(SlipTheme.muted)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 12)

            HStack(spacing: 4) {
                Text(cta)
                    .font(SlipTheme.labelMono())
                    .foregroundStyle(SlipTheme.primary)
                Image(systemName: "arrow.forward")
                    .font(.slipSystem(size: 11, weight: .semibold))
                    .foregroundStyle(SlipTheme.primary)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 168, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            SlipTheme.cardHigh.opacity(0.80),
                            SlipTheme.card.opacity(0.60)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(SlipTheme.glassBorder, lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.40), radius: 16, y: 8)
                .overlay(alignment: .bottomTrailing) {
                    Circle()
                        .fill(glow)
                        .frame(width: 80, height: 80)
                        .blur(radius: 20)
                        .padding(8)
                        .allowsHitTesting(false)
                }
        }
    }

    // MARK: - Category Chips

    private var categoryChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(categories, id: \.self) { cat in
                    let selected = selectedCategory == cat
                    Button {
                        selectedCategory = cat
                    } label: {
                        Text(cat)
                            .font(.slipSystem(size: 12, weight: selected ? .bold : .medium))
                            .foregroundStyle(selected ? Color.black : SlipTheme.muted)
                            .padding(.horizontal, 14)
                            .frame(height: 32)
                            .background(
                                Capsule().fill(selected ? Color.white : SlipTheme.cardHigh.opacity(0.55))
                            )
                            .overlay(
                                Capsule().strokeBorder(
                                    selected ? Color.white : Color.white.opacity(0.08),
                                    lineWidth: 1
                                )
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Brand Section Header

    private var brandsHeader: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Supported Brands")
                    .font(SlipTheme.headlineSM())
                    .foregroundStyle(SlipTheme.ink)
                Text("Official pass layouts & live dynamic sync")
                    .font(SlipTheme.bodySM())
                    .foregroundStyle(SlipTheme.muted)
            }
            Spacer()
            Text("\(filteredBrands.count) AVAILABLE")
                .font(SlipTheme.labelMono())
                .tracking(0.6)
                .foregroundStyle(SlipTheme.muted)
        }
    }

    // MARK: - Template List

    private var templateList: some View {
        VStack(spacing: 12) {
            ForEach(filteredBrands) { brand in
                Button {
                    onSelectBrand(brand)
                } label: {
                    templateRow(brand)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func templateRow(_ brand: BrandSummary) -> some View {
        let meta = marketplaceMeta(for: brand)
        return VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(meta.tint.opacity(0.22))
                        .frame(width: 46, height: 46)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .strokeBorder(meta.tint.opacity(0.4), lineWidth: 1)
                        )
                    if let icon = meta.systemIcon {
                        Image(systemName: icon)
                            .font(.slipSystem(size: 20, weight: .semibold))
                            .foregroundStyle(meta.tint)
                    } else {
                        Text(meta.badge)
                            .font(SlipTheme.labelMono())
                            .fontWeight(.bold)
                            .foregroundStyle(meta.tint)
                    }
                }

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 8) {
                        Text(brand.displayName)
                            .font(SlipTheme.headlineSM())
                            .foregroundStyle(SlipTheme.ink)
                        Text(meta.category.uppercased())
                            .font(.slipSystem(size: 10, weight: .bold, design: .monospaced))
                            .tracking(0.6)
                            .foregroundStyle(meta.tint)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2.5)
                            .background(Capsule().fill(meta.tint.opacity(0.15)))
                    }
                    Text(meta.blurb)
                        .font(SlipTheme.bodySM())
                        .foregroundStyle(SlipTheme.muted)
                        .lineLimit(2)
                }

                Spacer(minLength: 4)

                Text("+ Template")
                    .font(SlipTheme.labelMono())
                    .foregroundStyle(SlipTheme.ink)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(
                        Capsule()
                            .fill(SlipTheme.glassSurface)
                            .overlay(Capsule().strokeBorder(SlipTheme.glassBorder, lineWidth: 1))
                    )
            }
            .padding(14)

            // Mini Pass Preview Strip matching Stitch
            if let pLeft = meta.previewLeft, let pRight = meta.previewRight {
                Divider().background(SlipTheme.glassBorder)
                HStack {
                    if meta.hasFlightIcons {
                        HStack(spacing: 5) {
                            Text("DEL")
                                .font(SlipTheme.labelMono())
                                .fontWeight(.bold)
                                .foregroundStyle(SlipTheme.ink)
                            Image(systemName: "airplane.departure")
                                .font(.slipSystem(size: 11))
                                .foregroundStyle(SlipTheme.muted)
                            Text("BLR")
                                .font(SlipTheme.labelMono())
                                .fontWeight(.bold)
                                .foregroundStyle(SlipTheme.ink)
                        }
                    } else {
                        Text(pLeft)
                            .font(SlipTheme.labelMono())
                            .foregroundStyle(SlipTheme.muted)
                    }

                    Spacer()

                    Text(pRight)
                        .font(SlipTheme.labelMono())
                        .foregroundStyle(meta.tint)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(SlipTheme.cardHigh.opacity(0.65))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(SlipTheme.glassBorder, lineWidth: 1)
                )
        )
    }

    // MARK: - Custom Pass Promo Banner

    private var customPassPromoBanner: some View {
        Button {
            let customBrand = BrandSummary(
                id: "custom",
                displayName: "Custom PassKit",
                category: "generic",
                appleStyle: "generic",
                requiredFields: ["title", "code"],
                optionalFields: ["header", "details"],
                supportsLocations: false,
                supportsRelevantDate: false,
                accentHint: nil,
                stationCatalog: nil,
                summary: "Build a custom PKPass template in seconds",
                badge: "Custom",
                iconHint: "plus.circle.fill"
            )
            onSelectBrand(customBrand)
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(SlipTheme.glassSurface)
                        .frame(width: 38, height: 38)
                    Image(systemName: "plus.circle.fill")
                        .font(.slipSystem(size: 20, weight: .semibold))
                        .foregroundStyle(SlipTheme.ink)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Can't find your brand?")
                        .font(SlipTheme.headlineSM())
                        .foregroundStyle(SlipTheme.ink)
                    Text("Build a custom PKPass template in seconds")
                        .font(.slipSystem(size: 11, weight: .regular))
                        .foregroundStyle(SlipTheme.muted)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.slipSystem(size: 14, weight: .semibold))
                    .foregroundStyle(SlipTheme.muted)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(SlipTheme.cardHigh.opacity(0.5))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                            .foregroundStyle(SlipTheme.glassBorder)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private var emptyState: some View {
        GlassCard(cornerRadius: 16, padding: 18) {
            VStack(alignment: .leading, spacing: 8) {
                Text("No matching brands")
                    .font(SlipTheme.headlineSM())
                    .foregroundStyle(SlipTheme.ink)
                Text("Try another category or clear the search.")
                    .font(SlipTheme.bodySM())
                    .foregroundStyle(SlipTheme.muted)
            }
        }
    }

    // MARK: - Filtering

    private var filteredBrands: [BrandSummary] {
        let source = model.brands.isEmpty ? BrandSummary.fallbackCatalog : model.brands
        return source.filter { brand in
            let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
            let matchesQuery = q.isEmpty
                || brand.displayName.localizedCaseInsensitiveContains(q)
                || brand.id.localizedCaseInsensitiveContains(q)
                || brand.category.localizedCaseInsensitiveContains(q)
            return matchesQuery && matchesCategory(brand)
        }
    }

    private func matchesCategory(_ brand: BrandSummary) -> Bool {
        let cat = brand.category.lowercased()
        let id = brand.id.lowercased()
        switch selectedCategory {
        case "All":
            return true
        case "Transit & Flights":
            return cat.contains("transit") || cat.contains("travel") || id.contains("indigo")
                || id.contains("irctc") || id.contains("metro") || id.contains("flight")
        case "Cinema & Events":
            return cat.contains("event") || id.contains("bookmyshow") || id.contains("district")
                || id.contains("cinema")
        case "Dining & Nightlife":
            return cat.contains("dining") || id.contains("zomato") || id.contains("swiggy")
                || id.contains("eazydiner") || id.contains("dine")
        case "Keys & Mobility":
            return cat.contains("key") || cat.contains("mobility") || id.contains("uber")
                || id.contains("ola") || id.contains("airbnb") || id.contains("zoomcar")
        case "Fintech & UPI":
            return cat.contains("upi") || cat.contains("fintech") || cat.contains("retail")
                || id.contains("upi") || id.contains("neu")
        default:
            return true
        }
    }

    private func marketplaceMeta(for brand: BrandSummary) -> (
        badge: String,
        tint: Color,
        category: String,
        blurb: String,
        previewLeft: String?,
        previewRight: String?,
        systemIcon: String?,
        hasFlightIcons: Bool
    ) {
        let id = brand.id.lowercased()
        if id.contains("indigo") {
            return (
                "6E",
                Color(hex: 0x3B82F6),
                "Transit",
                "Boarding passes & web check-in sync",
                "DEL -> BLR",
                "Barcode & NFC Ready",
                nil,
                true
            )
        }
        if id.contains("irctc") {
            return (
                "IR",
                Color(hex: 0xEF4444),
                "Railways",
                "Train e-tickets & live PNR tracker",
                "PNR Status Push Alerts",
                "Coach / Berth HUD",
                "train.side.front.car",
                false
            )
        }
        if id.contains("bookmyshow") {
            return (
                "BMS",
                Color(hex: 0xF43F5E),
                "Cinema",
                "M-tickets & festival wristband passes",
                "Cinema Screen QR & Gate Pass",
                "Audi 4 • Recliner",
                "ticket.fill",
                false
            )
        }
        if id.contains("district") || id.contains("zomato") {
            return (
                "Z",
                Color(hex: 0xEF4444),
                "Experiences",
                "Concerts, dining reservations & lounge access",
                "Dineout QR & Table Priority",
                "VIP Lounge Pass",
                "fork.knife",
                false
            )
        }
        if id.contains("swiggy") {
            return (
                "S",
                Color(hex: 0xF97316),
                "Dining",
                "Privilege member pass & instant bill discounts",
                "Member Privileges Active",
                "15% Off Total Bill",
                "fork.knife",
                false
            )
        }
        if id.contains("zoomcar") {
            return (
                "ZC",
                Color(hex: 0x10B981),
                "Car Key",
                "Keyless Apple VAS NFC door unlock pass",
                "NFC Turnstile / Vehicle Ready",
                "Digital Key Paired",
                "key.fill",
                false
            )
        }
        if id.contains("metro") {
            return (
                "NM",
                Color(hex: 0xA855F7),
                "Metro",
                "Auto-reloading QR transit gates & passes",
                "Auto-reload balance ₹450",
                "Turnstile NFC",
                "tram.fill",
                false
            )
        }
        if id.contains("upi") {
            return (
                "₹",
                SlipTheme.upiGreen,
                "Fintech",
                "Virtual handle card with rapid QR scan recipient",
                "NPCI / Bharat QR Compliant",
                "Instant Settlement",
                "indianrupeesign",
                false
            )
        }
        if id.contains("cult") {
            return (
                "CF",
                Color(hex: 0xEC4899),
                "Fitness",
                "Gym access & class check-in pass",
                "Active Centre: Indiranagar",
                "Check-in QR Ready",
                "figure.run",
                false
            )
        }
        let initial = String(brand.displayName.prefix(2)).uppercased()
        return (
            initial,
            SlipTheme.primary,
            brand.categoryTitle,
            brand.summary ?? "Official pass layout",
            "Apple Wallet Ready",
            "VAS 2.0 & QR",
            nil,
            false
        )
    }
}
