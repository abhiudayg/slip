import SwiftUI

/// Step between OCR/QR ingest and field extraction: confirm (or override) the brand.
struct BrandSelectSheet: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.dismiss) private var dismiss

    let pending: PendingImport
    @State private var selectedId: String
    @State private var isAdvancing = false

    init(pending: PendingImport) {
        self.pending = pending
        let initial = pending.suggestedTemplateId.trimmingCharacters(in: .whitespacesAndNewlines)
        _selectedId = State(initialValue: initial)
    }

    private var catalog: [BrandSummary] {
        model.brands.isEmpty ? BrandSummary.fallbackCatalog : model.brands
    }

    private var selectedBrand: BrandSummary? {
        catalog.first { $0.id == selectedId }
    }

    var body: some View {
        ZStack {
            MeshBackground()
            VStack(spacing: 0) {
                header
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        suggestionCard
                        Text("Or pick another brand")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(SlipTheme.muted)
                            .padding(.top, 4)
                        brandList
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 120)
                }
            }

            VStack {
                Spacer()
                nextBar
            }
        }
        .interactiveDismissDisabled(isAdvancing)
    }

    private var header: some View {
        HStack {
            Button {
                model.pendingImport = nil
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(SlipTheme.ink)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(Color.white.opacity(0.08)))
            }
            .buttonStyle(.plain)
            .disabled(isAdvancing)

            VStack(alignment: .leading, spacing: 2) {
                Text("Confirm brand")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(SlipTheme.ink)
                Text("Extraction starts after you tap Next")
                    .font(.caption)
                    .foregroundStyle(SlipTheme.muted)
            }
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 12)
    }

    private var suggestionCard: some View {
        GlassCard(cornerRadius: 22, padding: 16) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 10) {
                    Image(systemName: "sparkles")
                        .foregroundStyle(SlipTheme.accentSoft)
                    Text(hasSuggestion ? "Slip thinks this is" : "Couldn’t match a brand")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(SlipTheme.muted)
                    Spacer()
                    if hasSuggestion {
                        Text("\(Int(pending.confidence * 100))%")
                            .font(.caption.weight(.bold).monospacedDigit())
                            .foregroundStyle(SlipTheme.accentSoft)
                    }
                }

                Text(hasSuggestion ? pending.suggestedDisplayName : "Pick from the list below")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(SlipTheme.ink)

                if !pending.rationale.isEmpty {
                    Text(pending.rationale)
                        .font(.caption)
                        .foregroundStyle(SlipTheme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if hasSuggestion {
                    Button {
                        selectedId = pending.suggestedTemplateId
                    } label: {
                        Label(
                            selectedId == pending.suggestedTemplateId ? "Using AI suggestion" : "Use AI suggestion",
                            systemImage: selectedId == pending.suggestedTemplateId ? "checkmark.circle.fill" : "arrow.uturn.backward"
                        )
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .foregroundStyle(selectedId == pending.suggestedTemplateId ? .black : SlipTheme.ink)
                        .background(
                            Capsule().fill(
                                selectedId == pending.suggestedTemplateId
                                    ? Color.white
                                    : Color.white.opacity(0.08)
                            )
                        )
                    }
                    .buttonStyle(.plain)
                }

                previewSnippet
            }
        }
    }

    private var previewSnippet: some View {
        let text = pending.ticket.recognizedText.trimmingCharacters(in: .whitespacesAndNewlines)
        let qr = pending.ticket.qrPayload?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return VStack(alignment: .leading, spacing: 6) {
            if !qr.isEmpty {
                Label(String(qr.prefix(64)), systemImage: "qrcode")
                    .font(.caption2.monospaced())
                    .foregroundStyle(SlipTheme.muted)
                    .lineLimit(1)
            }
            if !text.isEmpty {
                Text(String(text.prefix(160)) + (text.count > 160 ? "…" : ""))
                    .font(.caption2)
                    .foregroundStyle(SlipTheme.muted.opacity(0.9))
                    .lineLimit(3)
            }
        }
        .padding(.top, 4)
    }

    private var brandList: some View {
        VStack(spacing: 8) {
            ForEach(catalog) { brand in
                Button {
                    selectedId = brand.id
                } label: {
                    HStack(spacing: 12) {
                        Circle()
                            .fill(SlipTheme.color(fromRGB: brand.accentHint) ?? SlipTheme.accent)
                            .frame(width: 12, height: 12)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(brand.displayName)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(SlipTheme.ink)
                            Text(brand.categoryTitle)
                                .font(.caption2)
                                .foregroundStyle(SlipTheme.muted)
                        }
                        Spacer()
                        if selectedId == brand.id {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(SlipTheme.accentSoft)
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(selectedId == brand.id ? Color.white.opacity(0.12) : Color.white.opacity(0.05))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .strokeBorder(
                                        selectedId == brand.id ? Color.white.opacity(0.28) : Color.white.opacity(0.08),
                                        lineWidth: 1
                                    )
                            )
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var nextBar: some View {
        VStack(spacing: 10) {
            Button {
                guard canAdvance else { return }
                Task { @MainActor in
                    isAdvancing = true
                    await model.confirmBrandAndExtract(templateId: selectedId)
                    isAdvancing = false
                }
            } label: {
                HStack {
                    if isAdvancing {
                        ProgressView()
                            .tint(.black)
                    }
                    Text(isAdvancing ? "Extracting…" : "Next · Extract fields")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .foregroundStyle(.black)
                .background(Capsule().fill(canAdvance ? Color.white : Color.white.opacity(0.35)))
            }
            .buttonStyle(.plain)
            .disabled(!canAdvance || isAdvancing)

            if let selectedBrand {
                Text("Will extract \(selectedBrand.displayName) fields")
                    .font(.caption2)
                    .foregroundStyle(SlipTheme.muted)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 28)
        .padding(.top, 12)
        .background(
            LinearGradient(
                colors: [Color.black.opacity(0), Color.black.opacity(0.85)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea(edges: .bottom)
        )
    }

    private var hasSuggestion: Bool {
        !pending.suggestedTemplateId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && pending.suggestedDisplayName.lowercased() != "unknown"
    }

    private var canAdvance: Bool {
        !selectedId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
