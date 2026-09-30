import SwiftUI

/// Artboard 4 — Pass Customization & Live Wallet Preview
struct PassDetailsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var model: AppModel
    @EnvironmentObject private var vault: PassVaultStore

    let brand: BrandSummary
    @State private var fields: [String: String]
    @State private var autoSurface = true
    @State private var triggerMode: TriggerMode = .geofence
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @State private var passData: Data?
    @State private var showWallet = false
    @State private var vaultRecordId: String?

    enum TriggerMode: String, CaseIterable {
        case geofence = "GPS Geofence"
        case departure = "Departure Time"
    }

    init(brand: BrandSummary, fields: [String: String] = [:]) {
        self.brand = brand
        var merged: [String: String] = [:]
        for key in brand.requiredFields + brand.optionalFields {
            merged[key] = fields[key] ?? ""
        }
        for (k, v) in fields where merged[k] == nil {
            merged[k] = v
        }
        _fields = State(initialValue: merged)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                MeshBackground()
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        subHeader
                        livePassCard
                        lockScreenTrigger
                        addButton
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Pass Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .foregroundStyle(SlipTheme.ink)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Image(systemName: "person.crop.circle.fill")
                        .foregroundStyle(SlipTheme.indigo)
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .alert("Couldn't create pass", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "")
            }
            .sheet(isPresented: $showWallet) {
                if let passData {
                    NavigationStack {
                        VStack(spacing: 20) {
                            Text("Pass ready")
                                .font(.title2.weight(.semibold))
                            AddToWalletButton(passData: passData) {
                                showWallet = false
                                dismiss()
                            }
                        }
                        .padding()
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Done") { showWallet = false; dismiss() }
                            }
                        }
                    }
                }
            }
        }
    }

    private var subHeader: some View {
        HStack {
            Button { dismiss() } label: {
                Label("Passes", systemImage: "chevron.left")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(SlipTheme.accentSoft)
            }
            Spacer()
            StatusPill(title: "Live Wallet Preview", tint: SlipTheme.accent)
            Spacer()
            Image(systemName: "square.and.arrow.up")
                .foregroundStyle(SlipTheme.muted)
        }
    }

    private var livePassCard: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    iconBadge(systemName: brandIcon, tint: brandTint)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(brand.displayName.uppercased())
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(SlipTheme.muted)
                        Text(headline)
                            .font(.title3.weight(.bold))
                            .foregroundStyle(SlipTheme.ink)
                    }
                    Spacer()
                    Text(styleBadge)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(SlipTheme.muted)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(Color.white.opacity(0.1)))
                }

                HStack {
                    routeEndpoint(code: originCode, name: originName)
                    VStack(spacing: 4) {
                        Image(systemName: "arrow.right")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(SlipTheme.accentSoft)
                        Text(durationLabel)
                            .font(.caption2)
                            .foregroundStyle(SlipTheme.muted)
                    }
                    .frame(maxWidth: .infinity)
                    routeEndpoint(code: destCode, name: destName)
                }

                HStack(spacing: 8) {
                    metaCell("Dep Time", value(for: ["dep", "departure", "time"], fallback: "14:30"))
                    metaCell("Seat / Coach", seatCoach)
                    metaCell("Passenger", value(for: ["passenger", "name"], fallback: "Guest"))
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Status")
                            .font(.caption2)
                            .foregroundStyle(SlipTheme.muted)
                        StatusPill(title: "CNF", tint: SlipTheme.accent)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(18)

            HStack(spacing: 14) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white)
                    .frame(width: 88, height: 88)
                    .overlay(
                        Image(systemName: "qrcode")
                            .font(.largeTitle)
                            .foregroundStyle(.black)
                    )
                VStack(alignment: .leading, spacing: 6) {
                    Text("PNR RECORD")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.black.opacity(0.5))
                    Text(pnr)
                        .font(.title3.weight(.bold).monospaced())
                        .foregroundStyle(.black)
                    Label("Apple Wallet NFC Ready", systemImage: "wave.3.right")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.black.opacity(0.65))
                }
                Spacer()
            }
            .padding(16)
            .background(Color.white)
        }
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
        )
    }

    private var lockScreenTrigger: some View {
        GlassCard(cornerRadius: 22, padding: 16) {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Label("Lock Screen Trigger", systemImage: "location.north.line")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(SlipTheme.ink)
                    Spacer()
                    Text("Auto-Surface")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(SlipTheme.indigo)
                }

                HStack(spacing: 8) {
                    ForEach(TriggerMode.allCases, id: \.self) { mode in
                        let selected = triggerMode == mode
                        Button {
                            triggerMode = mode
                        } label: {
                            Label(
                                mode.rawValue,
                                systemImage: mode == .geofence ? "location.fill" : "clock.fill"
                            )
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(selected ? .white : SlipTheme.muted)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(
                                Capsule().fill(selected ? SlipTheme.indigo : Color.white.opacity(0.08))
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }

                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(SlipTheme.indigo.opacity(0.2))
                            .frame(width: 56, height: 56)
                        Circle()
                            .fill(SlipTheme.indigo)
                            .frame(width: 12, height: 12)
                            .shadow(color: SlipTheme.indigo, radius: 8)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text(originName)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(SlipTheme.ink)
                        Text("500m Active")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(SlipTheme.accentSoft)
                        Text("Card automatically displays on Dynamic Island & lock display when arriving near platforms.")
                            .font(.caption2)
                            .foregroundStyle(SlipTheme.muted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                Toggle(isOn: $autoSurface) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Auto-surface on Lock Screen")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(SlipTheme.ink)
                        Text("Prioritizes over regular widgets near station")
                            .font(.caption2)
                            .foregroundStyle(SlipTheme.muted)
                    }
                }
                .tint(SlipTheme.indigo)
            }
        }
    }

    private var addButton: some View {
        VStack(spacing: 10) {
            Button {
                Task { await createPass() }
            } label: {
                HStack {
                    if isSubmitting {
                        ProgressView().tint(.black)
                    } else {
                        Image(systemName: "wallet.pass.fill")
                        Text("Add to Apple Wallet")
                            .font(.headline)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .foregroundStyle(.black)
                .background(Capsule().fill(Color.white))
            }
            .disabled(isSubmitting)
            .buttonStyle(.plain)

            Label("Stored in Apple Secure Enclave · Syncs to Apple Watch", systemImage: "lock.shield")
                .font(.caption2)
                .foregroundStyle(SlipTheme.muted)
                .frame(maxWidth: .infinity)
        }
    }

    private func routeEndpoint(code: String, name: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(code)
                .font(.system(size: 28, weight: .bold))
                .tracking(-0.5)
                .foregroundStyle(SlipTheme.ink)
            Text(name)
                .font(.caption2)
                .foregroundStyle(SlipTheme.muted)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func metaCell(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(SlipTheme.muted)
            Text(value)
                .font(.caption.weight(.semibold))
                .foregroundStyle(SlipTheme.ink)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func iconBadge(systemName: String, tint: Color) -> some View {
        Image(systemName: systemName)
            .foregroundStyle(.white)
            .frame(width: 40, height: 40)
            .background(Circle().fill(tint))
    }

    private var brandTint: Color {
        SlipTheme.color(fromRGB: brand.accentHint) ?? SlipTheme.accent
    }

    private var brandIcon: String {
        switch brand.id {
        case "cult": return "figure.run"
        case "namma-metro": return "tram.fill"
        case "indigo": return "airplane"
        case "bookmyshow": return "ticket.fill"
        case "upi": return "qrcode"
        default: return "train.side.front.car"
        }
    }

    private var styleBadge: String {
        switch brand.appleStyle {
        case "boardingPass": return "BOARDING"
        case "storeCard": return "STORE"
        case "eventTicket": return "EVENT"
        default: return brand.appleStyle.uppercased()
        }
    }

    private var headline: String {
        if brand.id == "irctc" {
            return value(for: ["train", "flight"], fallback: "12640 BRINDAVAN EXP")
        }
        if brand.id == "indigo" {
            return value(for: ["flight"], fallback: "6E 524")
        }
        return brand.displayName
    }

    private var originCode: String {
        abbreviate(value(for: ["origin"], fallback: "SBC"))
    }

    private var destCode: String {
        abbreviate(value(for: ["destination"], fallback: "MAS"))
    }

    private var originName: String {
        value(for: ["origin"], fallback: "Bengaluru City Jn")
    }

    private var destName: String {
        value(for: ["destination"], fallback: "Chennai Central")
    }

    private var durationLabel: String { "5h 45m" }

    private var seatCoach: String {
        let seat = value(for: ["seat", "coach"], fallback: "C2 · 44")
        return seat
    }

    private var pnr: String {
        value(for: ["pnr", "booking_id", "qr_data"], fallback: "4218-9032-11")
    }

    private func value(for keys: [String], fallback: String) -> String {
        for key in keys {
            if let v = fields[key], !v.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
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

    private func createPass() async {
        isSubmitting = true
        defer { isSubmitting = false }
        do {
            // Seal into vault before leaving device memory for the signing round-trip.
            let payload = PassVaultPayload(
                templateId: brand.id,
                displayName: brand.displayName,
                fields: fields,
                stationIds: [],
                relevantDateISO8601: nil,
                rationale: "Saved from pass details",
                confidence: 1,
                qrPayload: fields["qr_data"],
                barcodeSymbology: nil,
                recognizedText: nil
            )
            let record = try vault.save(payload: payload, walletAdded: false)
            vaultRecordId = record.id

            let request = CreatePassRequest(
                template: brand.id,
                fields: fields,
                locations: nil,
                stationIds: nil,
                relevantDate: nil,
                barcodeFormat: nil
            )
            passData = try await model.api.createPass(request)
            if let vaultRecordId,
               let saved = vault.records.first(where: { $0.id == vaultRecordId }) {
                try? vault.markWalletAdded(saved)
            }
            showWallet = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
