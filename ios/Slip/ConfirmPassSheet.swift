import SwiftUI

/// Artboard 3 — AI Screenshot Scanner & Auto-Detection Modal
struct ConfirmPassSheet: View {
    @EnvironmentObject private var model: AppModel
    @EnvironmentObject private var vault: PassVaultStore
    @Environment(\.dismiss) private var dismiss

    @State private var classification: ClassificationResult
    @State private var showMarketplace = false
    @State private var showPassDetails = false
    @State private var showManualEdit = false
    @State private var vaultError: String?

    init(classification: ClassificationResult) {
        _classification = State(initialValue: classification)
    }

    var body: some View {
        ZStack {
            MeshBackground()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    topBar
                    neuralHeader
                    ticketPreview
                    autoMatchedCard
                    fieldSummary
                    liveActivityToggle
                    primaryActions
                    privacyFooter
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 36)
            }
        }
        .sheet(isPresented: $showMarketplace) {
            MarketplacePicker { brand in
                applyBrand(brand)
                showMarketplace = false
            }
            .environmentObject(model)
        }
        .sheet(isPresented: $showPassDetails) {
            if let brand = resolvedBrand {
                PassDetailsView(brand: brand, fields: classification.fields)
                    .environmentObject(model)
            }
        }
        .sheet(isPresented: $showManualEdit) {
            NavigationStack {
                Form {
                    ForEach(editableKeys, id: \.self) { key in
                        TextField(label(for: key), text: binding(for: key), axis: key == "qr_data" ? .vertical : .horizontal)
                    }
                    if classification.needsManualBrandPick || classification.templateId.isEmpty {
                        Button("Choose brand…") { showMarketplace = true }
                    }
                }
                .navigationTitle("Edit Fields")
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") { showManualEdit = false }
                    }
                }
            }
            .presentationDetents([.medium, .large])
        }
    }

    private var topBar: some View {
        HStack {
            Button {
                model.pendingClassification = nil
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(SlipTheme.ink)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(Color.white.opacity(0.08)))
            }
            Spacer()
            Text("AI Extraction Sheet")
                .font(.headline)
                .foregroundStyle(SlipTheme.ink)
            Spacer()
            Image(systemName: "person.crop.circle.fill")
                .font(.title2)
                .foregroundStyle(SlipTheme.indigo)
        }
    }

    private var neuralHeader: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Apple Vision Neural Engine · On-Device", systemImage: "brain.head.profile")
                .font(.caption.weight(.semibold))
                .foregroundStyle(SlipTheme.accentSoft)
            Text("AI Pass Extraction")
                .font(.system(size: 28, weight: .bold))
                .tracking(-0.4)
                .foregroundStyle(SlipTheme.ink)
            Text("High-confidence metadata isolated from screenshot stream")
                .font(.subheadline)
                .foregroundStyle(SlipTheme.muted)
        }
    }

    private var ticketPreview: some View {
        GlassCard(cornerRadius: 24, padding: 16) {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    HStack(spacing: 8) {
                        Text("IR")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.white)
                            .frame(width: 28, height: 28)
                            .background(RoundedRectangle(cornerRadius: 8).fill(SlipTheme.indigo))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(classification.displayName.isEmpty ? "Detected Pass" : classification.displayName)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(SlipTheme.ink)
                            Text("PNR: \(pnrDisplay)")
                                .font(.caption.monospaced())
                                .foregroundStyle(SlipTheme.muted)
                        }
                    }
                    Spacer()
                    Text("CONFIRMED")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(SlipTheme.upiGreen)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(Capsule().fill(SlipTheme.upiGreen.opacity(0.15)))
                }

                HStack {
                    routeBlock(
                        time: value(["dep", "departure"], "14:30"),
                        code: abbreviate(value(["origin"], "SBC")),
                        detail: value(["origin"], "Bengaluru")
                    )
                    VStack(spacing: 4) {
                        Text(value(["distance"], "362 KM"))
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(SlipTheme.muted)
                        Image(systemName: "arrow.right")
                            .foregroundStyle(SlipTheme.accentSoft)
                        Text(value(["duration"], "05h 45m"))
                            .font(.caption2)
                            .foregroundStyle(SlipTheme.muted)
                    }
                    .frame(maxWidth: .infinity)
                    routeBlock(
                        time: value(["arr", "arrival"], "20:15"),
                        code: abbreviate(value(["destination"], "MAS")),
                        detail: value(["destination"], "Chennai")
                    )
                }

                HStack {
                    Label(value(["passenger", "name"], "Passenger"), systemImage: "person.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(SlipTheme.ink)
                    Spacer()
                    Text(value(["seat", "coach"], "Seat pending"))
                        .font(.caption)
                        .foregroundStyle(SlipTheme.muted)
                    StatusPill(title: "2D QR OK", tint: SlipTheme.upiGreen)
                }
            }
        }
    }

    private var autoMatchedCard: some View {
        GlassCard(cornerRadius: 18, padding: 14) {
            HStack {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundStyle(SlipTheme.accent)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Auto-Matched Pass")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(SlipTheme.ink)
                    Text(classification.rationale.isEmpty ? "Template selected from on-device classifier" : classification.rationale)
                        .font(.caption)
                        .foregroundStyle(SlipTheme.muted)
                        .lineLimit(2)
                }
                Spacer()
                Text("\(Int(classification.confidence * 100))%")
                    .font(.caption.weight(.bold).monospacedDigit())
                    .foregroundStyle(SlipTheme.accentSoft)
            }
        }
    }

    private var fieldSummary: some View {
        GlassCard(cornerRadius: 22, padding: 4) {
            VStack(spacing: 0) {
                summaryRow("Origin", value(["origin"], "—"), icon: "mappin.and.ellipse")
                rowDivider
                summaryRow("Destination", value(["destination"], "—"), icon: "location.fill")
                rowDivider
                summaryRow("Train & Seat", "\(value(["train"], classification.displayName)) · \(value(["seat", "coach"], "—"))", icon: "train.side.front.car")
                rowDivider
                summaryRow("Departure", value(["relevantDate", "dep", "departure"], classification.relevantDateISO8601 ?? "—"), icon: "clock.fill")
            }
        }
    }

    private var liveActivityToggle: some View {
        GlassCard(cornerRadius: 18, padding: 14) {
            Label("Add Live Activity to Dynamic Island", systemImage: "rectangle.on.rectangle.angled")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(SlipTheme.ink)
        }
    }

            private var primaryActions: some View {
        VStack(spacing: 10) {
            Button {
                persistToVaultThenContinue()
            } label: {
                Label("Generate Pass with Apple AI", systemImage: "sparkles")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .foregroundStyle(.black)
                    .background(Capsule().fill(Color.white))
            }
            .buttonStyle(.plain)

            Button {
                showManualEdit = true
            } label: {
                Label("Edit Extracted Fields Manually", systemImage: "pencil.line")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .foregroundStyle(SlipTheme.ink)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.08))
                            .overlay(Capsule().strokeBorder(Color.white.opacity(0.14), lineWidth: 1))
                    )
            }
            .buttonStyle(.plain)
        }
    }

    private var privacyFooter: some View {
        Label("Processed locally · Slip · On-Device", systemImage: "lock.fill")
            .font(.caption2)
            .foregroundStyle(SlipTheme.muted)
            .frame(maxWidth: .infinity)
    }

    private func routeBlock(time: String, code: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(time)
                .font(.title3.weight(.bold).monospacedDigit())
                .foregroundStyle(SlipTheme.ink)
            Text(code)
                .font(.caption.weight(.bold))
                .foregroundStyle(SlipTheme.accentSoft)
            Text(detail)
                .font(.caption2)
                .foregroundStyle(SlipTheme.muted)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func summaryRow(_ title: String, _ value: String, icon: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(SlipTheme.accentSoft)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption2)
                    .foregroundStyle(SlipTheme.muted)
                Text(value)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(SlipTheme.ink)
            }
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
    }

    private var rowDivider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.08))
            .frame(height: 0.5)
            .padding(.leading, 48)
    }

    private var editableKeys: [String] {
        let preferred = ["name", "qr_data", "origin", "destination", "passenger", "membership", "event", "seat", "venue", "booking_id", "pnr", "coach", "train", "flight", "gate"]
        let keys = Set(classification.fields.keys)
        return preferred.filter { keys.contains($0) } + keys.subtracting(preferred).sorted()
    }

    private var resolvedBrand: BrandSummary? {
        let brands = model.brands.isEmpty ? BrandSummary.fallbackCatalog : model.brands
        if let match = brands.first(where: { $0.id == classification.templateId }) {
            return match
        }
        // Synthesize from classification when template isn't in the live catalog yet
        return BrandSummary(
            id: classification.templateId.isEmpty ? "upi" : classification.templateId,
            displayName: classification.displayName.isEmpty ? "Pass" : classification.displayName,
            category: "transit",
            appleStyle: "boardingPass",
            requiredFields: Array(classification.fields.keys),
            optionalFields: [],
            supportsLocations: true,
            supportsRelevantDate: true,
            accentHint: "rgb(94, 92, 230)",
            stationCatalog: nil,
            summary: nil,
            badge: "Scan",
            iconHint: "qrcode.viewfinder"
        )
    }

    private var pnrDisplay: String {
        value(["pnr", "booking_id"], "—")
    }

    private func value(_ keys: [String], _ fallback: String) -> String {
        for key in keys {
            if let v = classification.fields[key], !v.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return v
            }
        }
        return fallback
    }

    private func abbreviate(_ text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.count <= 4 { return trimmed.uppercased() }
        if let paren = trimmed.split(separator: "(").last?.split(separator: ")").first, paren.count <= 4 {
            return String(paren).uppercased()
        }
        return String(trimmed.prefix(3)).uppercased()
    }

    private func binding(for key: String) -> Binding<String> {
        Binding(
            get: { classification.fields[key] ?? "" },
            set: { classification.fields[key] = $0 }
        )
    }

    private func label(for key: String) -> String {
        switch key {
        case "qr_data": return "QR / barcode payload"
        case "booking_id": return "Booking ID"
        default: return key.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }

    private func applyBrand(_ brand: BrandSummary) {
        classification.templateId = brand.id
        classification.displayName = brand.displayName
        classification.needsManualBrandPick = false
        classification.confidence = max(classification.confidence, 0.6)
        classification.rationale = "Brand selected from marketplace"
        for key in brand.requiredFields + brand.optionalFields {
            if classification.fields[key] == nil {
                classification.fields[key] = ""
            }
        }
        if classification.fields["qr_data"]?.isEmpty != false,
           let qr = classification.extracted.qrPayload {
            classification.fields["qr_data"] = qr
        }
        persistToVaultThenContinue()
    }

    /// Encrypt sensitive fields into the on-device vault before opening pass details.
    private func persistToVaultThenContinue() {
        do {
            if !classification.templateId.isEmpty {
                _ = try vault.save(from: classification)
            }
        } catch {
            vaultError = error.localizedDescription
        }
        if classification.needsManualBrandPick || classification.templateId.isEmpty {
            showMarketplace = true
        } else {
            showPassDetails = true
        }
    }
}

struct MarketplacePicker: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.dismiss) private var dismiss
    var onPick: (BrandSummary) -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                MeshBackground()
                List {
                    ForEach(model.brands.isEmpty ? BrandSummary.fallbackCatalog : model.brands) { brand in
                        Button {
                            onPick(brand)
                        } label: {
                            HStack {
                                Circle()
                                    .fill(SlipTheme.color(fromRGB: brand.accentHint) ?? SlipTheme.accent)
                                    .frame(width: 12, height: 12)
                                VStack(alignment: .leading) {
                                    Text(brand.displayName).foregroundStyle(SlipTheme.ink)
                                    Text(brand.categoryTitle).font(.caption).foregroundStyle(SlipTheme.muted)
                                }
                            }
                        }
                        .listRowBackground(SlipTheme.card)
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Marketplace")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}
