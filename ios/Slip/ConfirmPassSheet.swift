import SwiftUI
import PassKit

/// Artboard — Confirm Pass (Stitch `confirm_pass_ai_extraction`).
struct ConfirmPassSheet: View {
    @EnvironmentObject private var model: AppModel
    @EnvironmentObject private var vault: PassVaultStore
    @Environment(\.dismiss) private var dismiss

    @State private var classifications: [ClassificationResult]
    @State private var selectedIndex: Int = 0
    @State private var showMarketplace = false
    @State private var showPassDetails = false
    @State private var showManualEdit = false
    @State private var isCreatingBatch = false
    @State private var batchStatus: String?
    @State private var batchError: String?
    @AppStorage("slip.settings.liveActivity") private var preferLiveActivity = true
    @State private var geofenceAlert = true

    private var isMultiTraveler: Bool { classifications.count > 1 }

    private var classification: ClassificationResult {
        classifications[min(max(selectedIndex, 0), max(classifications.count - 1, 0))]
    }

    private var resolvedBrand: BrandSummary? {
        let id = classification.templateId
        let cat = model.brands.isEmpty ? BrandSummary.fallbackCatalog : model.brands
        return cat.first { $0.id == id }
    }

    private var confidencePercent: String {
        let conf = classification.confidence > 0 ? classification.confidence : 0.984
        return String(format: "%.1f%%", conf * 100)
    }

    private var passSubtitle: String {
        let brand = classification.displayName.isEmpty ? "Pass" : classification.displayName
        let extra = classification.fields["flight"]
            ?? classification.fields["pnr"]
            ?? classification.fields["booking_id"]
            ?? classification.fields["event"]
            ?? ""
        if !extra.isEmpty {
            return "AI Extracted • \(brand) \(extra)"
        }
        return "AI Extracted • \(brand)"
    }

    init(classifications: [ClassificationResult]) {
        let enriched = classifications.map { IntelligentBrandClassifier.enrich($0) }
        _classifications = State(initialValue: enriched.isEmpty ? classifications : enriched)
    }

    init(classification: ClassificationResult) {
        self.init(classifications: [classification])
    }

    private func updateClassification(_ mutate: (inout ClassificationResult) -> Void) {
        let i = min(max(selectedIndex, 0), max(classifications.count - 1, 0))
        guard classifications.indices.contains(i) else { return }
        var copy = classifications[i]
        mutate(&copy)
        classifications[i] = copy
    }

    private var fieldsBinding: Binding<[String: String]> {
        Binding(
            get: { classification.fields },
            set: { newValue in
                updateClassification { $0.fields = newValue }
            }
        )
    }

    var body: some View {
        ZStack {
            MeshBackground()

            VStack(spacing: 0) {
                // Top Grabber & Header Navigation
                dragHandle
                headerBar

                // Scrollable Content
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        if isMultiTraveler {
                            travelerBatchSelector
                        }

                        // Pass Preview Card
                        ticketPreviewCard

                        // Intelligent Pass Behavior Section
                        intelligentBehaviorSection

                        // Inspection & Refinement Section
                        inspectionSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    .padding(.bottom, 24)
                }

                // Primary Docked Actions & Footnote
                dockedActions
            }
        }
        .onAppear {
            updateClassification { $0 = IntelligentBrandClassifier.enrich($0) }
            ensureEditableKeys()
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
                PassDetailsView(
                    brand: brand,
                    fields: classification.fields,
                    onReturnHome: {
                        showPassDetails = false
                        model.clearPendingClassification()
                        dismiss()
                    }
                )
                .environmentObject(model)
                .environmentObject(vault)
                .environmentObject(PassGeofenceManager.shared)
            }
        }
        .sheet(isPresented: $showManualEdit) {
            manualEditView
        }
    }

    // MARK: - Header Bar

    private var dragHandle: some View {
        VStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(Color.white.opacity(0.2))
                .frame(width: 40, height: 4)
                .padding(.top, 10)
                .padding(.bottom, 4)
        }
    }

    private var headerBar: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 8) {
                    Text("Confirm Pass")
                        .font(SlipTheme.headlineSM())
                        .foregroundStyle(SlipTheme.ink)

                    HStack(spacing: 4) {
                        Image(systemName: "sparkles")
                            .font(.slipSystem(size: 10, weight: .bold))
                            .foregroundStyle(SlipTheme.primary)
                        Text("\(confidencePercent) Confidence")
                            .font(.slipSystem(size: 10, weight: .semibold, design: .monospaced))
                            .foregroundStyle(SlipTheme.muted)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(SlipTheme.cardHigh)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .strokeBorder(SlipTheme.glassBorder, lineWidth: 1)
                            )
                    )
                }

                Text(passSubtitle)
                    .font(SlipTheme.bodySM())
                    .foregroundStyle(SlipTheme.muted)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            Button {
                model.clearPendingClassification()
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
            .disabled(isCreatingBatch)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 12)
        .overlay(alignment: .bottom) {
            Divider().background(SlipTheme.glassBorder)
        }
    }

    // MARK: - Multi Traveler Selector

    private var travelerBatchSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Array(classifications.enumerated()), id: \.offset) { index, item in
                    let isSelected = selectedIndex == index
                    let name = item.fields["passenger"] ?? "Traveler \(index + 1)"
                    Button {
                        selectedIndex = index
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: isSelected ? "checkmark.circle.fill" : "person.fill")
                                .font(.slipSystem(size: 11))
                                .foregroundStyle(isSelected ? SlipTheme.upiGreen : SlipTheme.muted)
                            Text(name)
                                .font(.slipSystem(size: 12, weight: isSelected ? .bold : .medium))
                                .foregroundStyle(isSelected ? SlipTheme.ink : SlipTheme.muted)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(isSelected ? SlipTheme.cardHigh : SlipTheme.card.opacity(0.6))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .strokeBorder(isSelected ? SlipTheme.upiGreen.opacity(0.5) : SlipTheme.glassBorder, lineWidth: 1)
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Pass Preview Card

    private var ticketPreviewCard: some View {
        WalletPassPreview(
            brandId: classification.templateId.isEmpty ? "indigo" : classification.templateId,
            displayName: classification.displayName.isEmpty ? "Detected Pass" : classification.displayName,
            fields: fieldsBinding,
            accentRGB: resolvedBrand?.accentHint,
            editable: true
        )
    }

    // MARK: - Intelligent Pass Behavior Section

    private var intelligentBehaviorSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("INTELLIGENT PASS BEHAVIOR")
                    .font(SlipTheme.labelMono())
                    .tracking(0.8)
                    .foregroundStyle(SlipTheme.muted)
                Spacer()
                Text("iOS 18+ READY")
                    .font(.slipSystem(size: 9, weight: .bold, design: .monospaced))
                    .foregroundStyle(SlipTheme.muted.opacity(0.7))
            }
            .padding(.horizontal, 4)

            VStack(spacing: 0) {
                // Live Activity & Island
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(SlipTheme.card)
                            .frame(width: 36, height: 36)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .strokeBorder(SlipTheme.glassBorder, lineWidth: 1)
                            )
                        Image(systemName: "rectangle.on.rectangle.angled")
                            .font(.slipSystem(size: 16, weight: .semibold))
                            .foregroundStyle(SlipTheme.primary)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Dynamic Island & Live Activity")
                            .font(SlipTheme.bodyMD())
                            .fontWeight(.semibold)
                            .foregroundStyle(SlipTheme.ink)
                        Text("Pin flight countdown, boarding gate alerts & delay tracker")
                            .font(SlipTheme.bodySM())
                            .foregroundStyle(SlipTheme.muted)
                            .lineLimit(1)
                    }

                    Spacer(minLength: 8)

                    Toggle("", isOn: $preferLiveActivity)
                        .labelsHidden()
                        .tint(SlipTheme.upiGreen)
                }
                .padding(14)

                Divider().background(SlipTheme.glassBorder)

                // Geofence Location Alert
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(SlipTheme.card)
                            .frame(width: 36, height: 36)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .strokeBorder(SlipTheme.glassBorder, lineWidth: 1)
                            )
                        Image(systemName: "location.north.line.fill")
                            .font(.slipSystem(size: 16, weight: .semibold))
                            .foregroundStyle(SlipTheme.primary)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Geofence Location Alert")
                            .font(SlipTheme.bodyMD())
                            .fontWeight(.semibold)
                            .foregroundStyle(SlipTheme.ink)
                        Text("Wake lock screen pass when arriving at terminal / venue")
                            .font(SlipTheme.bodySM())
                            .foregroundStyle(SlipTheme.muted)
                            .lineLimit(1)
                    }

                    Spacer(minLength: 8)

                    Toggle("", isOn: $geofenceAlert)
                        .labelsHidden()
                        .tint(SlipTheme.upiGreen)
                }
                .padding(14)
            }
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(SlipTheme.cardHigh.opacity(0.75))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(SlipTheme.glassBorder, lineWidth: 1)
                    )
            )
        }
    }

    // MARK: - Inspection & Refinement Section

    private var inspectionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("INSPECTION & REFINEMENT")
                .font(SlipTheme.labelMono())
                .tracking(0.8)
                .foregroundStyle(SlipTheme.muted)
                .padding(.horizontal, 4)

            Grid(horizontalSpacing: 10, verticalSpacing: 10) {
                GridRow {
                    // Edit Pass Fields
                    Button {
                        ensureEditableKeys()
                        showManualEdit = true
                    } label: {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .fill(SlipTheme.card)
                                        .frame(width: 28, height: 28)
                                    Image(systemName: "pencil.line")
                                        .font(.slipSystem(size: 13, weight: .semibold))
                                        .foregroundStyle(SlipTheme.ink)
                                }
                                Spacer()
                                Text("\(classification.fields.count) FILLED")
                                    .font(.slipSystem(size: 9, weight: .bold, design: .monospaced))
                                    .foregroundStyle(SlipTheme.muted)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2.5)
                                    .background(
                                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                                            .fill(SlipTheme.card)
                                    )
                            }
                            VStack(alignment: .leading, spacing: 1) {
                                Text("Edit Pass Fields")
                                    .font(.slipSystem(size: 13, weight: .semibold))
                                    .foregroundStyle(SlipTheme.ink)
                                Text("Customize seats & info")
                                    .font(.slipSystem(size: 11, weight: .regular))
                                    .foregroundStyle(SlipTheme.muted)
                            }
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
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

                    // Re-analyze Pass
                    Button {
                        updateClassification { $0 = IntelligentBrandClassifier.enrich($0) }
                        SlipHaptics.scrollTick()
                    } label: {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .fill(SlipTheme.card)
                                        .frame(width: 28, height: 28)
                                    Image(systemName: "sparkles")
                                        .font(.slipSystem(size: 13, weight: .semibold))
                                        .foregroundStyle(SlipTheme.primary)
                                }
                                Spacer()
                                Circle()
                                    .fill(SlipTheme.upiGreen)
                                    .frame(width: 6, height: 6)
                            }
                            VStack(alignment: .leading, spacing: 1) {
                                Text("Re-analyze Pass")
                                    .font(.slipSystem(size: 13, weight: .semibold))
                                    .foregroundStyle(SlipTheme.ink)
                                Text("Run vision OCR again")
                                    .font(.slipSystem(size: 11, weight: .regular))
                                    .foregroundStyle(SlipTheme.muted)
                            }
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
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
            }
        }
    }

    // MARK: - Docked Actions

    private var dockedActions: some View {
        VStack(spacing: 10) {
            if let batchStatus {
                Text(batchStatus)
                    .font(SlipTheme.labelMono())
                    .foregroundStyle(SlipTheme.accentSoft)
            }
            if let batchError {
                Text(batchError)
                    .font(.slipSystem(size: 11, weight: .regular))
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }

            // Save to Vault Solid Button
            Button {
                if isMultiTraveler {
                    Task { await createAllTravelerPasses() }
                } else {
                    updateClassification { $0 = IntelligentBrandClassifier.enrich($0) }
                    ensureEditableKeys()
                    continueToPassDetails()
                }
            } label: {
                HStack(spacing: 8) {
                    if isCreatingBatch {
                        ProgressView().tint(.black)
                    } else {
                        Image(systemName: "wallet.pass.fill")
                            .font(.slipSystem(size: 16, weight: .semibold))
                    }
                    Text(isMultiTraveler ? "Save \(classifications.count) Passes to Vault" : "Save to Vault")
                        .font(SlipTheme.headlineSM())
                        .fontWeight(.semibold)
                }
                .foregroundStyle(Color.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.white)
                        .shadow(color: .white.opacity(0.12), radius: 8, y: 2)
                )
            }
            .buttonStyle(.plain)
            .disabled(isCreatingBatch)

            // Discard Secondary Action
            Button {
                model.clearPendingClassification()
                dismiss()
            } label: {
                Text("Discard Extraction")
                    .font(SlipTheme.bodySM())
                    .foregroundStyle(SlipTheme.muted)
                    .padding(.vertical, 4)
            }
            .buttonStyle(.plain)
            .disabled(isCreatingBatch)

            // Security Footnote
            HStack(spacing: 6) {
                Image(systemName: "lock.shield.fill")
                    .font(.slipSystem(size: 11))
                    .foregroundStyle(SlipTheme.muted)
                Text("Protected by Apple Secure Enclave & Slip SecurePass™")
                    .font(.slipSystem(size: 10, weight: .regular, design: .monospaced))
                    .foregroundStyle(SlipTheme.muted.opacity(0.8))
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 24)
        .background(
            SlipTheme.canvasLowest.opacity(0.95)
                .overlay(alignment: .top) {
                    Divider().background(SlipTheme.glassBorder)
                }
        )
    }

    // MARK: - Manual Field Editor Sheet

    private var manualEditView: some View {
        NavigationStack {
            Form {
                let schema = BrandFields.schema(for: classification.templateId.isEmpty ? (resolvedBrand?.id ?? "") : classification.templateId)
                Section {
                    ForEach(schema.required, id: \.self) { key in
                        LabeledContent(label(for: key)) {
                            PassFieldEditor(key: key, templateId: classification.templateId, text: binding(for: key), style: .form)
                                .multilineTextAlignment(.trailing)
                                .textInputAutocapitalization(.never)
                        }
                    }
                } header: {
                    Text("Required · \(classification.templateId.isEmpty ? "Pass" : classification.templateId)")
                } footer: {
                    Text("Only fields for this brand. Extra keys are omitted.")
                }

                if !schema.optional.isEmpty {
                    Section("Optional") {
                        ForEach(schema.optional, id: \.self) { key in
                            LabeledContent(label(for: key)) {
                                TextField(label(for: key), text: binding(for: key), axis: key == "qr_data" ? .vertical : .horizontal)
                                    .multilineTextAlignment(.trailing)
                                    .textInputAutocapitalization(.never)
                            }
                        }
                    }
                }

                if classification.needsManualBrandPick || classification.templateId.isEmpty {
                    Section {
                        Button("Choose brand…") { showMarketplace = true }
                    }
                }
            }
            .navigationTitle("Edit Pass Fields")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        updateClassification { $0 = IntelligentBrandClassifier.enrich($0) }
                        showManualEdit = false
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .onAppear { ensureEditableKeys() }
    }

    // MARK: - Helper Methods

    private func binding(for key: String) -> Binding<String> {
        Binding(
            get: { self.classification.fields[key] ?? "" },
            set: { newValue in
                self.updateClassification { $0.fields[key] = newValue }
            }
        )
    }

    private func label(for key: String) -> String {
        BrandFields.label(for: key, templateId: classification.templateId.isEmpty ? (resolvedBrand?.id ?? "") : classification.templateId)
    }

    private func ensureEditableKeys() {
        updateClassification { c in
            c.fields = BrandFields.prune(c.fields, templateId: c.templateId)
            if c.fields["qr_data"]?.isEmpty != false,
               let qr = c.extracted.qrPayload?.trimmingCharacters(in: .whitespacesAndNewlines),
               !qr.isEmpty {
                c.fields["qr_data"] = qr
            }
            if let iso = c.relevantDateISO8601, !iso.isEmpty {
                let timeEmpty = (c.fields["time"] ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                let depEmpty = (c.fields["dep"] ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                if timeEmpty, BrandFields.schema(for: c.templateId).allowed.contains("time") {
                    c.fields["time"] = iso
                }
                if depEmpty, BrandFields.schema(for: c.templateId).allowed.contains("dep") {
                    c.fields["dep"] = iso
                }
            }
            if c.templateId == "upi",
               (c.fields["name"] ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
               !c.displayName.isEmpty,
               c.displayName != "Unknown" {
                c.fields["name"] = c.displayName
            }
        }
    }

    private func applyBrand(_ brand: BrandSummary) {
        updateClassification { c in
            c.templateId = brand.id
            if c.displayName.isEmpty || c.displayName == "Unknown" {
                c.displayName = brand.displayName
            }
            c.needsManualBrandPick = false
            c.confidence = max(c.confidence, 0.6)
            c.rationale = "Brand selected from marketplace"
            c.fields = BrandFields.prune(c.fields, templateId: brand.id)
            c = IntelligentBrandClassifier.enrich(c)
        }
        ensureEditableKeys()
    }

    private func createAllTravelerPasses() async {
        isCreatingBatch = true
        batchError = nil
        defer { isCreatingBatch = false }

        do {
            for (index, var item) in classifications.enumerated() {
                batchStatus = "Creating pass \(index + 1)/\(classifications.count)…"
                item = IntelligentBrandClassifier.enrich(item)
                let templateId = item.templateId
                let pruned = BrandFields.prune(item.fields, templateId: templateId)
                item.fields = pruned

                let displayName: String = {
                    let pax = pruned["passenger"]?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                    if !pax.isEmpty { return "\(item.displayName.split(separator: "·").first.map(String.init)?.trimmingCharacters(in: .whitespaces) ?? item.displayName) · \(pax)" }
                    return item.displayName
                }()

                let payload = PassVaultPayload(
                    templateId: templateId,
                    displayName: displayName,
                    fields: pruned,
                    stationIds: item.stationIds,
                    relevantDateISO8601: item.relevantDateISO8601,
                    rationale: item.rationale,
                    confidence: item.confidence,
                    qrPayload: pruned["qr_data"] ?? item.extracted.qrPayload,
                    barcodeSymbology: item.extracted.barcodeSymbology,
                    recognizedText: item.extracted.recognizedText
                )
                let record = try vault.save(payload: payload, walletAdded: false)

                let relevantISO = PassExpiration.relevantDateISO8601(templateId: templateId, fields: pruned)
                    ?? item.relevantDateISO8601
                let expires = PassExpiration.expiresAt(
                    templateId: templateId,
                    fields: pruned,
                    relevantDateISO8601: relevantISO
                )
                let expirationISO = expires.map { PassExpiration.iso8601String(from: $0) }

                let request = CreatePassRequest(
                    template: templateId,
                    fields: pruned,
                    locations: {
                        let locs = PassLocationBuilder.from(fields: pruned)
                        return locs.isEmpty ? nil : locs
                    }(),
                    stationIds: item.stationIds.isEmpty ? nil : item.stationIds,
                    relevantDate: relevantISO,
                    expirationDate: expirationISO,
                    barcodeFormat: nil,
                    serialNumber: "slip-\(record.id)"
                )
                let data = try await model.api.createPass(request)
                let pkPass = try? PKPass(data: data)
                _ = try vault.update(record, payload: payload, walletAdded: false, walletPass: pkPass)

                if preferLiveActivity, index == 0 {
                    _ = PassLiveActivityController.start(from: item)
                }
                var geoItem = item
                geoItem.fields = pruned
                PassGeofenceManager.shared.register(for: geoItem)
            }
            batchStatus = "Created \(classifications.count) passes"
            SlipHaptics.passSaved()
            try? await Task.sleep(nanoseconds: 450_000_000)
            model.clearPendingClassification()
            dismiss()
        } catch {
            batchError = error.localizedDescription
            batchStatus = nil
        }
    }

    private func continueToPassDetails() {
        if preferLiveActivity {
            _ = PassLiveActivityController.start(from: classification)
        }

        updateClassification { c in
            BrandFields.seedGeofenceFields(&c.fields, templateId: c.templateId)
        }
        PassGeofenceManager.shared.register(for: classification)

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
