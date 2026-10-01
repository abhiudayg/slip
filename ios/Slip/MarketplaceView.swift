import PhotosUI
import SwiftUI

/// Artboard 2 — Template Marketplace & Category Directory
struct MarketplaceView: View {
    @EnvironmentObject private var model: AppModel
    @State private var query = ""
    @State private var selectedCategory = "All Passes"
    var onClose: (() -> Void)? = nil
    var onSelectBrand: (BrandSummary) -> Void
    var onScanScreenshot: () -> Void
    var onImportPDF: (() -> Void)? = nil

    private let categories = ["All Passes", "Transit", "Fitness", "Travel", "Events", "Dining", "Retail", "Personal UPI"]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                topBar
                searchField
                categoryChips
                curatedHeader
                templateList
                if filteredBrands.isEmpty {
                    emptyState
                }
                aiPrompt
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 120)
        }
    }

    private var topBar: some View {
        Group {
            if let onClose {
                HStack {
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(SlipTheme.ink)
                            .frame(width: 36, height: 36)
                            .background(Circle().fill(Color.white.opacity(0.08)))
                    }
                    Spacer()
                    Text("Templates")
                        .font(.headline)
                        .foregroundStyle(SlipTheme.ink)
                    Spacer()
                    Color.clear.frame(width: 36, height: 36)
                }
            } else {
                StudioTopBar(title: "New Pass")
            }
        }
    }

    private var searchField: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(SlipTheme.muted)
            TextField("Search templates", text: $query)
                .foregroundStyle(SlipTheme.ink)
                .textInputAutocapitalization(.never)
            Image(systemName: "mic.fill")
                .foregroundStyle(SlipTheme.muted)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.black.opacity(0.35))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }

    private var categoryChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(categories, id: \.self) { cat in
                    let selected = selectedCategory == cat
                    Button {
                        selectedCategory = cat
                    } label: {
                        Text(cat)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(selected ? SlipTheme.ink : SlipTheme.muted)
                            .padding(.horizontal, selected ? 16 : 14)
                            .frame(height: 32)
                            .background(
                                Capsule().fill(selected ? Color.white.opacity(0.15) : SlipTheme.cardHigh.opacity(0.55))
                            )
                            .overlay(
                                Capsule().strokeBorder(Color.white.opacity(selected ? 0.18 : 0.06), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var curatedHeader: some View {
        HStack(alignment: .firstTextBaseline) {
            HStack(spacing: 8) {
                Text("Curated Templates")
                    .font(.system(size: 17, weight: .semibold))
                    .tracking(-0.2)
                    .foregroundStyle(SlipTheme.ink)
                Text("Verified Spec")
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(0.6)
                    .textCase(.uppercase)
                    .foregroundStyle(SlipTheme.muted)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(SlipTheme.cardHigh))
            }
            Spacer()
            Text("\(filteredBrands.count) Available")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(SlipTheme.muted)
        }
    }

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
        return GlassCard(cornerRadius: 22, padding: 16) {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: meta.icon)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(meta.tint))

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(meta.spec)
                            .font(.system(size: 10, weight: .bold))
                            .tracking(0.5)
                            .foregroundStyle(meta.tint)
                        Spacer()
                        Text(meta.badge)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(SlipTheme.muted)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(Color.white.opacity(0.08)))
                    }
                    Text(brand.displayName)
                        .font(.headline)
                        .foregroundStyle(SlipTheme.ink)
                    Text(meta.blurb)
                        .font(.caption)
                        .foregroundStyle(SlipTheme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                    HStack {
                        Text(meta.tag)
                            .font(.system(size: 10, weight: .bold))
                            .tracking(0.6)
                            .foregroundStyle(SlipTheme.accentSoft)
                        Spacer()
                        Image(systemName: "arrow.right")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(SlipTheme.ink)
                            .frame(width: 28, height: 28)
                            .background(Circle().fill(Color.white.opacity(0.1)))
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        GlassCard(cornerRadius: 22, padding: 20) {
            VStack(alignment: .leading, spacing: 10) {
                Label("No Templates Matched", systemImage: "magnifyingglass")
                    .font(.headline)
                    .foregroundStyle(SlipTheme.ink)
                Text("Create a custom pass using our universal image scanner or open payload tool.")
                    .font(.caption)
                    .foregroundStyle(SlipTheme.muted)
                Button("Clear Search") {
                    query = ""
                    selectedCategory = "All Passes"
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(SlipTheme.accentSoft)
            }
        }
    }

    private var aiPrompt: some View {
        GlassCard(cornerRadius: 22, padding: 16) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 12) {
                    Image(systemName: "sparkles")
                        .foregroundStyle(SlipTheme.amber)
                        .frame(width: 40, height: 40)
                        .background(Circle().fill(SlipTheme.amber.opacity(0.15)))
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Have a ticket?")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(SlipTheme.ink)
                        Text("Import a screenshot or booking PDF — Slip extracts QR and fields on-device.")
                            .font(.caption)
                            .foregroundStyle(SlipTheme.muted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                HStack(spacing: 10) {
                    Button("Scan", action: onScanScreenshot)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Capsule().fill(SlipTheme.accent))
                    if let onImportPDF {
                        Button("Import PDF", action: onImportPDF)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(SlipTheme.ink)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(Capsule().fill(Color.white.opacity(0.1)))
                            .overlay(Capsule().strokeBorder(Color.white.opacity(0.16), lineWidth: 1))
                    }
                }
            }
        }
    }

    private var filteredBrands: [BrandSummary] {
        let brands = model.brands.isEmpty ? BrandSummary.fallbackCatalog : model.brands
        return brands.filter { brand in
            let matchesQuery = query.isEmpty
                || brand.displayName.localizedCaseInsensitiveContains(query)
                || brand.category.localizedCaseInsensitiveContains(query)
                || (brand.summary?.localizedCaseInsensitiveContains(query) ?? false)
            let matchesCategory: Bool = {
                switch selectedCategory {
                case "All Passes": return true
                case "Transit": return brand.category == "transit"
                case "Fitness": return brand.category == "fitness"
                case "Travel": return ["travel", "transit"].contains(brand.category)
                case "Events": return brand.category == "entertainment"
                case "Dining": return brand.category == "dining"
                case "Retail": return brand.category == "retail"
                case "Personal UPI": return brand.category == "everyday_pay"
                default: return true
                }
            }()
            return matchesQuery && matchesCategory
        }
    }

    private func marketplaceMeta(for brand: BrandSummary) -> (icon: String, tint: Color, spec: String, badge: String, blurb: String, tag: String) {
        let tint = SlipTheme.color(fromRGB: brand.accentHint) ?? SlipTheme.accent
        let spec: String = {
            switch brand.appleStyle {
            case "boardingPass": return "Boarding Pass"
            case "storeCard": return "Store Card"
            case "eventTicket": return "Event Ticket"
            case "coupon": return "Coupon"
            default: return "Generic Pass"
            }
        }()
        return (
            brand.sfSymbol,
            tint,
            spec,
            brand.badge ?? brand.categoryTitle,
            brand.summary ?? "Template served by pass-engine `/v1/brands`.",
            brand.categoryTitle.uppercased()
        )
    }
}
