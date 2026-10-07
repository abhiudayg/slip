import SwiftUI

/// Artboard — Select Brand Template (Stitch `brandselectsheet_slip_wallet`).
struct BrandSelectSheet: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.dismiss) private var dismiss

    let pending: PendingImport
    @State private var selectedId: String
    @State private var isAdvancing = false

    init(pending: PendingImport) {
        self.pending = pending
        let initial = pending.suggestedTemplateId.trimmingCharacters(in: .whitespacesAndNewlines)
        _selectedId = State(initialValue: initial.isEmpty ? "indigo" : initial)
    }

    private var hasSuggestion: Bool {
        !pending.suggestedTemplateId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var confidencePercent: Int {
        Int((pending.confidence > 0 ? pending.confidence : 0.98) * 100)
    }

    private struct CategoryItem: Identifiable {
        let id: String
        let title: String
        let subtitle: String
        let badge: String
        let icon: String
        let tint: Color
        let templateId: String
    }

    private let categories: [CategoryItem] = [
        CategoryItem(
            id: "transit",
            title: "Transit & Flights",
            subtitle: "IndiGo, British Airways, Air India",
            badge: "Dynamic Gate & Boarding",
            icon: "airplane.departure",
            tint: Color(hex: 0x38BDF8),
            templateId: "indigo"
        ),
        CategoryItem(
            id: "rail",
            title: "Railways & Metro",
            subtitle: "IRCTC Rail, Namma Metro, DMRC",
            badge: "Live PNR & Tap-In",
            icon: "tram.fill",
            tint: Color(hex: 0xF87171),
            templateId: "irctc"
        ),
        CategoryItem(
            id: "cinema",
            title: "Movies & Cinema",
            subtitle: "BookMyShow, PVR INOX, Cinepolis",
            badge: "Seat Map & Audio F&B",
            icon: "film.fill",
            tint: Color(hex: 0xFB7185),
            templateId: "bookmyshow"
        ),
        CategoryItem(
            id: "dining",
            title: "Dining & Reservations",
            subtitle: "Swiggy Dineout, Zomato, EazyDiner",
            badge: "Table Priority NFC",
            icon: "fork.knife",
            tint: Color(hex: 0xC084FC),
            templateId: "zomato"
        ),
        CategoryItem(
            id: "mobility",
            title: "Mobility & Car Keys",
            subtitle: "Zoomcar Keyless, Uber Ride Pass",
            badge: "BLE & Ultra Wideband",
            icon: "key.fill",
            tint: Color(hex: 0x34D399),
            templateId: "zoomcar"
        ),
        CategoryItem(
            id: "hotel",
            title: "Hotels & Keyless Keys",
            subtitle: "Airbnb Keyless, Marriott Bonvoy",
            badge: "Door Lock NFC Tap",
            icon: "bed.double.fill",
            tint: Color(hex: 0xFBBF24),
            templateId: "airbnb"
        ),
        CategoryItem(
            id: "fitness",
            title: "Fitness & Gym Access",
            subtitle: "CultPass Elite, Anytime Fitness",
            badge: "Turnstile QR & Barcode",
            icon: "figure.run",
            tint: Color(hex: 0xFB923C),
            templateId: "cult"
        ),
        CategoryItem(
            id: "fintech",
            title: "Payments & Virtual",
            subtitle: "UPI PayPass, Tata Neu Rewards",
            badge: "Tokenized VAS 2.0",
            icon: "creditcard.fill",
            tint: Color(hex: 0x22D3EE),
            templateId: "upi"
        )
    ]

    var body: some View {
        ZStack {
            MeshBackground()

            VStack(spacing: 0) {
                // Top Drag Handle & Safe Header
                dragHandle
                headerBar

                // Scrollable Content
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        if hasSuggestion {
                            aiSuggestionHeroCard
                        }

                        categoriesGridHeader
                        categoriesGrid
                        customTemplateCard
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    .padding(.bottom, 24)
                }

                // Fixed Footer Actions
                footerActions
            }
        }
        .interactiveDismissDisabled(isAdvancing)
    }

    // MARK: - Drag Handle & Header

    private var dragHandle: some View {
        VStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(Color.white.opacity(0.2))
                .frame(width: 44, height: 5)
                .padding(.top, 10)
                .padding(.bottom, 6)
        }
    }

    private var headerBar: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 8) {
                    Text("Select Brand Template")
                        .font(SlipTheme.headlineSM())
                        .foregroundStyle(SlipTheme.ink)
                    Text("v2.4")
                        .font(SlipTheme.captionMono(10, weight: .bold))
                        .foregroundStyle(SlipTheme.muted)
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
                Text("Match your pass or ticket to a verified dynamic layout")
                    .font(SlipTheme.bodySM())
                    .foregroundStyle(SlipTheme.muted)
            }

            Spacer(minLength: 8)

            Button {
                model.pendingImport = nil
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.slipSystem(size: 13, weight: .semibold))
                    .foregroundStyle(SlipTheme.ink)
                    .frame(width: 32, height: 32)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(SlipTheme.cardHigh)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .strokeBorder(SlipTheme.glassBorder, lineWidth: 1)
                            )
                    )
            }
            .buttonStyle(.plain)
            .disabled(isAdvancing)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 12)
        .overlay(alignment: .bottom) {
            Divider().background(SlipTheme.glassBorder)
        }
    }

    // MARK: - AI Suggestion Card

    private var aiSuggestionHeroCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header: AI SUGGESTED MATCH + Confidence
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.slipSystem(size: 12, weight: .semibold))
                        .foregroundStyle(SlipTheme.ink)
                    Text("AI SUGGESTED MATCH")
                        .font(SlipTheme.labelMono(11, weight: .bold))
                        .tracking(0.8)
                        .foregroundStyle(SlipTheme.ink)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(SlipTheme.cardHigh)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .strokeBorder(SlipTheme.glassBorder, lineWidth: 1)
                        )
                )

                Spacer()

                HStack(spacing: 5) {
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .fill(SlipTheme.upiGreen)
                        .frame(width: 6, height: 6)
                    Text("\(confidencePercent)% Match")
                        .font(SlipTheme.labelMono())
                        .foregroundStyle(SlipTheme.primary)
                }
            }

            // Hero Details
            HStack(alignment: .top, spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [SlipTheme.meshViolet, SlipTheme.cardHigh],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 48, height: 48)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(SlipTheme.glassBorder, lineWidth: 1)
                        )
                    Image(systemName: "ticket.fill")
                        .font(.slipSystem(size: 22, weight: .semibold))
                        .foregroundStyle(SlipTheme.ink)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(pending.suggestedDisplayName)
                        .font(SlipTheme.headlineSM())
                        .foregroundStyle(SlipTheme.ink)
                    Text("Auto-extracts gate, seat, showtime, barcode & live dynamic event countdown.")
                        .font(SlipTheme.bodySM())
                        .foregroundStyle(SlipTheme.muted)
                        .lineLimit(2)
                }
            }

            // Feature Tag Strip (15% curvature, no pills)
            HStack(spacing: 8) {
                featureTag(icon: "wave.3.right", text: "Apple VAS 2.0 Ready")
                featureTag(icon: "sensor.tag.radiowaves.forward.fill", text: "NFC Turnstile")
                featureTag(icon: "arrow.triangle.2.circlepath", text: "Live Activity")
            }

            // Continue CTA Button (Squircle, no pill)
            Button {
                advanceWith(templateId: pending.suggestedTemplateId)
            } label: {
                HStack(spacing: 8) {
                    if isAdvancing {
                        ProgressView().tint(.black)
                    }
                    Text("Continue with Suggested Template")
                        .font(SlipTheme.bodyMD())
                        .fontWeight(.semibold)
                    Image(systemName: "arrow.forward")
                        .font(.slipSystem(size: 13, weight: .semibold))
                }
                .foregroundStyle(Color.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.white)
                        .shadow(color: .white.opacity(0.15), radius: 8, y: 2)
                )
            }
            .buttonStyle(.plain)
            .disabled(isAdvancing)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(SlipTheme.cardHigh.opacity(0.85))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [Color.white.opacity(0.3), Color.white.opacity(0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
    }

    private func featureTag(icon: String, text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.slipSystem(size: 10, weight: .semibold))
                .foregroundStyle(SlipTheme.muted)
            Text(text)
                .font(SlipTheme.captionMono(10, weight: .medium))
                .foregroundStyle(SlipTheme.muted)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(SlipTheme.card.opacity(0.7))
                .overlay(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .strokeBorder(SlipTheme.glassBorder, lineWidth: 1)
                )
        )
    }

    // MARK: - Categories Grid Header

    private var categoriesGridHeader: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Select your own category")
                    .font(SlipTheme.headlineSM())
                    .foregroundStyle(SlipTheme.ink)
                Text("Or pick a specialized layout template below")
                    .font(SlipTheme.bodySM())
                    .foregroundStyle(SlipTheme.muted)
            }
            Spacer()
            Text("9 Layouts")
                .font(SlipTheme.labelMono())
                .foregroundStyle(SlipTheme.muted)
        }
    }

    // MARK: - Categories Grid

    private var categoriesGrid: some View {
        Grid(horizontalSpacing: 10, verticalSpacing: 10) {
            ForEach(0..<categories.count / 2, id: \.self) { row in
                GridRow {
                    categoryCard(categories[row * 2])
                    categoryCard(categories[row * 2 + 1])
                }
            }
        }
    }

    private func categoryCard(_ item: CategoryItem) -> some View {
        Button {
            selectedId = item.templateId
            advanceWith(templateId: item.templateId)
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top, spacing: 10) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(item.tint.opacity(0.18))
                            .frame(width: 36, height: 36)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .strokeBorder(item.tint.opacity(0.3), lineWidth: 1)
                            )
                        Image(systemName: item.icon)
                            .font(.slipSystem(size: 16, weight: .semibold))
                            .foregroundStyle(item.tint)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.title)
                            .font(SlipTheme.inter(13, weight: .semibold))
                            .foregroundStyle(SlipTheme.ink)
                            .lineLimit(1)
                        Text(item.subtitle)
                            .font(SlipTheme.captionMono(10, weight: .regular))
                            .foregroundStyle(SlipTheme.muted)
                            .lineLimit(1)
                    }
                }

                Spacer(minLength: 4)

                HStack {
                    Text(item.badge)
                        .font(SlipTheme.captionMono(9, weight: .medium))
                        .foregroundStyle(SlipTheme.muted)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2.5)
                        .background(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(SlipTheme.card.opacity(0.8))
                        )
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.slipSystem(size: 11, weight: .semibold))
                        .foregroundStyle(SlipTheme.muted)
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, minHeight: 96, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(SlipTheme.cardHigh.opacity(0.65))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(SlipTheme.glassBorder, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Custom Template Card

    private var customTemplateCard: some View {
        Button {
            selectedId = "custom"
            advanceWith(templateId: "custom")
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(SlipTheme.glassSurface)
                        .frame(width: 36, height: 36)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .strokeBorder(SlipTheme.glassBorder, lineWidth: 1)
                        )
                    Image(systemName: "chevron.left.forwardslash.chevron.right")
                        .font(.slipSystem(size: 14, weight: .semibold))
                        .foregroundStyle(SlipTheme.ink)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Custom PassKit Template")
                        .font(.slipSystem(size: 13, weight: .semibold))
                        .foregroundStyle(SlipTheme.ink)
                    Text("Build your own with custom JSON fields, barcode & NFC payload")
                        .font(.slipSystem(size: 11, weight: .regular))
                        .foregroundStyle(SlipTheme.muted)
                        .lineLimit(1)
                }

                Spacer()

                HStack(spacing: 4) {
                    Text("PKPASS")
                        .font(SlipTheme.labelMono())
                        .foregroundStyle(SlipTheme.muted)
                    Image(systemName: "arrow.forward")
                        .font(.slipSystem(size: 12, weight: .semibold))
                        .foregroundStyle(SlipTheme.muted)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(SlipTheme.cardHigh.opacity(0.5))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                            .foregroundStyle(SlipTheme.glassBorder)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Footer Actions

    private var footerActions: some View {
        VStack(spacing: 10) {
            Button {
                selectedId = "custom"
                advanceWith(templateId: "custom")
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "square.and.pencil")
                        .font(.slipSystem(size: 15, weight: .semibold))
                        .foregroundStyle(SlipTheme.muted)
                    Text("Manual Pass Creator")
                        .font(SlipTheme.bodyMD())
                        .fontWeight(.medium)
                        .foregroundStyle(SlipTheme.ink)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(SlipTheme.cardHigh)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(SlipTheme.glassBorder, lineWidth: 1)
                        )
                )
            }
            .buttonStyle(.plain)

            HStack(spacing: 6) {
                Image(systemName: "lock.shield.fill")
                    .font(.slipSystem(size: 11))
                    .foregroundStyle(SlipTheme.upiGreen)
                Text("Encrypted on-device via Apple Secure Enclave & Slip SecurePass™")
                    .font(.slipSystem(size: 10, weight: .regular, design: .monospaced))
                    .foregroundStyle(SlipTheme.muted)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 24)
        .background(
            SlipTheme.canvasLowest.opacity(0.95)
                .overlay(alignment: .top) {
                    Divider().background(SlipTheme.glassBorder)
                }
        )
    }

    // MARK: - Actions

    private func advanceWith(templateId: String) {
        guard !isAdvancing else { return }
        Task { @MainActor in
            isAdvancing = true
            await model.confirmBrandAndExtract(templateId: templateId)
            isAdvancing = false
        }
    }
}
