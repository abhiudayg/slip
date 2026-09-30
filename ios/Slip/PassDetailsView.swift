import PassKit
import SwiftUI

/// Artboard 4 — Pass Customization & Live Wallet Preview
struct PassDetailsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var model: AppModel
    @EnvironmentObject private var vault: PassVaultStore
    @EnvironmentObject private var geofence: PassGeofenceManager

    let brand: BrandSummary
    var onReturnHome: (() -> Void)? = nil
    @State private var fields: [String: String]
    @State private var autoSurface = true
    @State private var triggerMode: TriggerMode = .geofence
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @State private var passData: Data?
    @State private var showWallet = false
    @State private var vaultRecordId: String?
    @State private var showFieldEditor = false
    @State private var alreadyInAppleWallet = false
    @State private var latestPKPass: PKPass?

    enum TriggerMode: String, CaseIterable {
        case geofence = "GPS Geofence"
        case departure = "Departure Time"
    }

    init(
        brand: BrandSummary,
        fields: [String: String] = [:],
        existingVaultRecordId: String? = nil,
        onReturnHome: (() -> Void)? = nil
    ) {
        self.brand = brand
        self.onReturnHome = onReturnHome
        var merged = BrandFields.prune(fields, templateId: brand.id)
        if (merged["booking_id"] ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
           let qr = merged["qr_data"], !qr.isEmpty {
            let first = qr.split(separator: ",").first.map(String.init)?
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if first.range(of: #"^[A-Z0-9]{5,12}$"#, options: .regularExpression) != nil {
                merged["booking_id"] = first.uppercased()
            }
        }
        _fields = State(initialValue: merged)
        _vaultRecordId = State(initialValue: existingVaultRecordId)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                MeshBackground()
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        subHeader
                        livePassCard
                        passFieldsSection
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
                    Button {
                        showFieldEditor = true
                    } label: {
                        Image(systemName: "pencil")
                            .foregroundStyle(SlipTheme.accentSoft)
                    }
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .onAppear { hydrateWalletLink() }
            .alert("Couldn't create pass", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("Edit fields") { showFieldEditor = true }
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "")
            }
            .sheet(isPresented: $showFieldEditor) {
                NavigationStack {
                    Form {
                        Section("Required") {
                            ForEach(BrandFields.schema(for: brand.id).required, id: \.self) { key in
                                LabeledContent(BrandFields.label(for: key, templateId: brand.id)) {
                                    TextField(BrandFields.label(for: key, templateId: brand.id), text: binding(for: key), axis: key == "qr_data" ? .vertical : .horizontal)
                                        .multilineTextAlignment(.trailing)
                                        .textInputAutocapitalization(.never)
                                }
                            }
                        }
                        let optional = BrandFields.schema(for: brand.id).optional
                        if !optional.isEmpty {
                            Section("Optional") {
                                ForEach(optional, id: \.self) { key in
                                    LabeledContent(BrandFields.label(for: key, templateId: brand.id)) {
                                        TextField(BrandFields.label(for: key, templateId: brand.id), text: binding(for: key))
                                            .multilineTextAlignment(.trailing)
                                            .textInputAutocapitalization(.never)
                                    }
                                }
                            }
                        }
                    }
                    .navigationTitle("Edit Pass Fields")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") { showFieldEditor = false }
                        }
                    }
                }
                .presentationDetents([.medium, .large])
            }
            .sheet(isPresented: $showWallet) {
                if let passData {
                    NavigationStack {
                        VStack(spacing: 20) {
                            Image(systemName: walletSheetIcon)
                                .font(.system(size: 44))
                                .foregroundStyle(walletSheetTint)
                            Text(walletSheetTitle)
                                .font(.title2.weight(.semibold))
                                .foregroundStyle(SlipTheme.ink)
                            Text(walletSheetSubtitle)
                                .font(.footnote)
                                .foregroundStyle(SlipTheme.muted)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 8)

                            if PKAddPassesViewController.canAddPasses() {
                                AddToWalletButton(passData: passData) { pass in
                                    latestPKPass = pass
                                    finishAfterWalletAdd(pass: pass)
                                }
                            } else {
                                Text("This device can’t add passes to Apple Wallet (Simulator or restricted PassKit). The pass is still saved in your Slip vault.")
                                    .font(.footnote)
                                    .foregroundStyle(SlipTheme.muted)
                                    .multilineTextAlignment(.center)
                                Button("Back to Home") {
                                    finishAfterWalletAdd(pass: latestPKPass)
                                }
                                .buttonStyle(.borderedProminent)
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(MeshBackground().ignoresSafeArea())
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Done") {
                                    showWallet = false
                                }
                            }
                        }
                    }
                    .presentationDetents([.medium, .large])
                    .onAppear { refreshWalletPresence(passData: passData) }
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
        WalletPassPreview(
            brandId: brand.id,
            displayName: brand.displayName,
            fields: $fields,
            accentRGB: brand.accentHint,
            editable: true
        )
    }

    /// Stitch-aligned editable fields for the live Wallet preview (all schema keys).
    private var passFieldsSection: some View {
        let schema = BrandFields.schema(for: brand.id)
        return GlassCard(cornerRadius: 22, padding: 16) {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Label("Pass Fields", systemImage: "list.bullet.rectangle")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(SlipTheme.ink)
                    Spacer()
                    Text("\(schema.all.count)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(SlipTheme.muted)
                }

                if !schema.required.isEmpty {
                    Text("Required")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(SlipTheme.accentSoft)
                        .textCase(.uppercase)
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(schema.required, id: \.self) { key in
                            fieldEditorCell(key)
                        }
                    }
                }

                if !schema.optional.isEmpty {
                    Text("Optional · Stitch layout")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(SlipTheme.muted)
                        .textCase(.uppercase)
                        .padding(.top, 4)
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(schema.optional, id: \.self) { key in
                            fieldEditorCell(key)
                        }
                    }
                }
            }
        }
    }

    private func fieldEditorCell(_ key: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(BrandFields.label(for: key, templateId: brand.id))
                .font(.caption2)
                .foregroundStyle(SlipTheme.muted)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
            TextField(
                BrandFields.label(for: key, templateId: brand.id),
                text: binding(for: key),
                axis: key == "qr_data" || key == "address" ? .vertical : .horizontal
            )
            .font(.caption.weight(.semibold))
            .foregroundStyle(SlipTheme.ink)
            .textInputAutocapitalization(key == "qr_data" ? .never : .words)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(0.06))
        )
    }

    private var isDiningStyle: Bool {
        ["easydiner", "zomato-dineout", "swiggy-dineout"].contains(brand.id) || brand.category == "dining"
    }

    private var isEventStyle: Bool {
        if isDiningStyle { return false }
        return brand.id == "bookmyshow" || brand.appleStyle == "eventTicket" || brand.category == "entertainment"
    }

    private var isRouteStyle: Bool {
        ["irctc", "indigo", "namma-metro", "redbus"].contains(brand.id) || brand.appleStyle == "boardingPass"
    }

    private var isStayStyle: Bool {
        brand.id == "airbnb"
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
                        Text(isStayStyle
                             ? value(for: ["property"], fallback: brand.displayName)
                             : (isEventStyle ? value(for: ["venue"], fallback: brand.displayName) : originName))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(SlipTheme.ink)
                        Text("350m · \(geofence.shortLabel)")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(SlipTheme.accentSoft)
                        Text(geofenceHelpText)
                            .font(.caption2)
                            .foregroundStyle(SlipTheme.muted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                if triggerMode == .geofence {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Location")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(SlipTheme.accentSoft)
                            .textCase(.uppercase)
                        TextField("Venue, address, or lat, lon", text: binding(for: "location"), axis: .vertical)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(SlipTheme.ink)
                            .padding(10)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(Color.white.opacity(0.06))
                            )
                            .onChange(of: fields["location"] ?? "") { _, _ in
                                syncSurfaceTriggers()
                            }
                        HStack(spacing: 10) {
                            TextField("Latitude", text: binding(for: "latitude"))
                                .font(.caption.weight(.semibold))
                                .keyboardType(.decimalPad)
                                .padding(10)
                                .background(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .fill(Color.white.opacity(0.06))
                                )
                                .onChange(of: fields["latitude"] ?? "") { _, _ in syncSurfaceTriggers() }
                            TextField("Longitude", text: binding(for: "longitude"))
                                .font(.caption.weight(.semibold))
                                .keyboardType(.decimalPad)
                                .padding(10)
                                .background(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .fill(Color.white.opacity(0.06))
                                )
                                .onChange(of: fields["longitude"] ?? "") { _, _ in syncSurfaceTriggers() }
                        }
                    }
                }

                Toggle(isOn: $autoSurface) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Auto-surface on Lock Screen")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(SlipTheme.ink)
                        Text("Prioritizes over regular widgets near this location")
                            .font(.caption2)
                            .foregroundStyle(SlipTheme.muted)
                    }
                }
                .tint(SlipTheme.indigo)
                .onChange(of: autoSurface) { _, _ in syncSurfaceTriggers() }
                .onChange(of: triggerMode) { _, _ in syncSurfaceTriggers() }
            }
        }
        .onAppear { syncSurfaceTriggers() }
    }

    private var geofenceHelpText: String {
        if triggerMode == .departure {
            return "Departure-time Lock Screen priority uses the ticket time when available. Geofences stay off in this mode."
        }
        switch geofence.authorizationStatus {
        case .authorizedAlways:
            if geofence.monitoredRegionCount > 0 {
                let plural = geofence.monitoredRegionCount == 1 ? "" : "s"
                let label = geofence.lastRegisteredLabel.map { " · \($0)" } ?? ""
                return "Monitoring \(geofence.monitoredRegionCount) region\(plural)\(label). You’ll get a notification on entry."
            }
            return "Always location granted. Add a Location (or lat/lon) so geofence can arm."
        case .authorizedWhenInUse:
            return "While Using is not enough for background wakeups — Slip will ask for Always when you enable auto-surface."
        case .denied, .restricted:
            return "Location is blocked. Enable Always for Slip in iOS Settings → Privacy → Location."
        case .notDetermined:
            return "Enable auto-surface to request Always location for venue geofences."
        @unknown default:
            return "Location status unknown."
        }
    }

    private func syncSurfaceTriggers() {
        guard autoSurface, triggerMode == .geofence else { return }
        if geofence.authorizationStatus == .notDetermined
            || geofence.authorizationStatus == .authorizedWhenInUse {
            geofence.requestAccess()
        }
        BrandFields.seedGeofenceFields(&fields, templateId: brand.id)
        geofence.register(
            fields: fields,
            templateId: brand.id,
            displayName: brand.displayName
        )
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
                        Text(isUpdatingExistingPass ? "Update Pass" : "Generate Pass")
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

            Label(
                PKAddPassesViewController.canAddPasses()
                    ? (isUpdatingExistingPass
                       ? "Updates vault · then Update in Apple Wallet (same pass)"
                       : "Saves to vault after generate · then Add to Apple Wallet")
                    : "Saves to vault after generate · this device can’t add Wallet passes",
                systemImage: PKAddPassesViewController.canAddPasses() ? "lock.shield" : "exclamationmark.triangle"
            )
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

    /// Stitch live wallet preview: info cells are inline-editable.
    private func metaCell(_ title: String, key: String, placeholder: String = "") -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(SlipTheme.muted)
            TextField(placeholder.isEmpty ? title : placeholder, text: binding(for: key))
                .font(.caption.weight(.semibold))
                .foregroundStyle(SlipTheme.ink)
                .lineLimit(1)
                .textInputAutocapitalization(.never)
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
        case "easydiner", "zomato-dineout", "swiggy-dineout": return "fork.knife"
        case "airbnb": return "house.fill"
        case "redbus": return "bus.fill"
        case "zoomcar": return "car.fill"
        case "namma-metro": return "tram.fill"
        case "indigo": return "airplane"
        case "bookmyshow", "district": return "ticket.fill"
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

    private var headlineKey: String {
        if isEventStyle { return "event" }
        if isStayStyle { return "property" }
        if isRouteStyle { return "origin" }
        return genericTitleKey
    }

    private var genericTitleKey: String {
        switch brand.id {
        case "easydiner", "zomato-dineout", "swiggy-dineout": return "restaurant"
        case "zoomcar": return "vehicle"
        case "upi": return "name"
        case "airbnb": return "property"
        default: return "name"
        }
    }

    private var genericTitlePlaceholder: String {
        switch brand.id {
        case "easydiner", "zomato-dineout", "swiggy-dineout": return "Restaurant"
        case "zoomcar": return "Vehicle"
        case "upi": return "Payee"
        default: return "Title"
        }
    }

    private var genericWhenKey: String {
        switch brand.id {
        case "zoomcar": return "pickup"
        case "airbnb": return "check_in"
        default: return "time"
        }
    }

    private var genericWhenLabel: String {
        switch brand.id {
        case "zoomcar": return "Pickup"
        case "airbnb": return "Check-in"
        default: return "When"
        }
    }

    private var genericPartyKey: String {
        switch brand.id {
        case "zoomcar": return "guest"
        default: return "party_size"
        }
    }

    private var genericPartyLabel: String {
        switch brand.id {
        case "zoomcar": return "Guest"
        default: return "Party"
        }
    }

    private var passengerKey: String {
        BrandFields.schema(for: brand.id).allowed.contains("passenger") ? "passenger" : "name"
    }

    private var passIdKey: String {
        let allowed = BrandFields.schema(for: brand.id).allowed
        if allowed.contains("booking_id") { return "booking_id" }
        if allowed.contains("pnr") { return "pnr" }
        if allowed.contains("qr_data") { return "qr_data" }
        return "booking_id"
    }

    private var headline: String {
        if brand.id == "bookmyshow" || brand.appleStyle == "eventTicket" {
            return value(for: ["event"], fallback: brand.displayName)
        }
        if brand.id == "airbnb" {
            return value(for: ["property"], fallback: brand.displayName)
        }
        if brand.id == "irctc" {
            return value(for: ["train", "flight"], fallback: brand.displayName)
        }
        if brand.id == "indigo" {
            return value(for: ["flight"], fallback: brand.displayName)
        }
        return brand.displayName
    }

    private var originCode: String {
        let raw = value(for: ["origin"], fallback: "")
        return raw.isEmpty ? "—" : abbreviate(raw)
    }

    private var destCode: String {
        let raw = value(for: ["destination"], fallback: "")
        return raw.isEmpty ? "—" : abbreviate(raw)
    }

    private var originName: String {
        value(for: ["origin"], fallback: "Origin")
    }

    private var destName: String {
        value(for: ["destination"], fallback: "Destination")
    }

    private var durationLabel: String {
        value(for: ["duration"], fallback: "—")
    }

    private var seatCoach: String {
        value(for: ["seat", "coach"], fallback: "—")
    }

    private var passIdValue: String {
        switch brand.id {
        case "upi":
            return value(for: ["name", "qr_data"], fallback: "—")
        case "bookmyshow", "district", "easydiner", "zomato-dineout", "swiggy-dineout", "zoomcar", "airbnb":
            return value(for: ["booking_id"], fallback: "—")
        case "irctc", "indigo", "redbus":
            return value(for: ["pnr"], fallback: "—")
        default:
            return value(for: ["booking_id", "pnr", "name"], fallback: "—")
        }
    }

    private var pnr: String { passIdValue }

    private func value(for keys: [String], fallback: String) -> String {
        for key in keys {
            if let v = fields[key], !v.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return v
            }
        }
        return fallback
    }

    private func binding(for key: String) -> Binding<String> {
        Binding(
            get: { fields[key] ?? "" },
            set: { fields[key] = $0 }
        )
    }

    private func fieldLabel(_ key: String) -> String {
        BrandFields.label(for: key, templateId: brand.id)
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

        // Backfill movie title into required `event` when the preview headline has it.
        if isEventStyle {
            let event = fields["event"]?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if event.isEmpty {
                let fallback = headline.trimmingCharacters(in: .whitespacesAndNewlines)
                if !fallback.isEmpty, fallback.lowercased() != brand.displayName.lowercased() {
                    fields["event"] = fallback
                }
            }
            if (fields["booking_id"] ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
               let qr = fields["qr_data"], !qr.isEmpty {
                let first = qr.split(separator: ",").first.map(String.init)?
                    .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                if first.range(of: #"^[A-Z0-9]{5,12}$"#, options: .regularExpression) != nil {
                    fields["booking_id"] = first.uppercased()
                }
            }
        }

        // Airbnb / dining confirmations rarely include a QR — Wallet barcode uses the booking id.
        if brand.id == "airbnb"
            || brand.id == "zoomcar"
            || ["easydiner", "zomato-dineout", "swiggy-dineout"].contains(brand.id) {
            let qr = fields["qr_data"]?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let booking = fields["booking_id"]?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if qr.isEmpty, !booking.isEmpty {
                fields["qr_data"] = booking
            }
        }

        let pruned = BrandFields.prune(fields, templateId: brand.id)
        fields = pruned

        let missing = BrandFields.schema(for: brand.id).required.filter {
            (pruned[$0] ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        if !missing.isEmpty {
            errorMessage = "Fill required fields first: \(missing.map { $0.replacingOccurrences(of: "_", with: " ") }.joined(separator: ", "))"
            showFieldEditor = true
            return
        }

        do {
            let relevantISO = PassExpiration.relevantDateISO8601(
                templateId: brand.id,
                fields: pruned
            )
            let expires = PassExpiration.expiresAt(
                templateId: brand.id,
                fields: pruned,
                relevantDateISO8601: relevantISO
            )
            let expirationISO = expires.map { PassExpiration.iso8601String(from: $0) }

            let reuseSerial = stableWalletSerial()
            if let reuseSerial,
               let id = vaultRecordId,
               let existing = vault.records.first(where: { $0.id == id }),
               existing.walletSerialNumber != reuseSerial {
                existing.walletSerialNumber = reuseSerial
                if let installed = WalletPassLink.libraryPass(serial: reuseSerial) {
                    existing.walletPassTypeIdentifier = installed.passTypeIdentifier
                    existing.walletAdded = true
                    alreadyInAppleWallet = true
                }
            }
            let request = CreatePassRequest(
                template: brand.id,
                fields: pruned,
                locations: {
                    let locs = PassLocationBuilder.from(fields: pruned)
                    return locs.isEmpty ? nil : locs
                }(),
                stationIds: nil,
                relevantDate: relevantISO,
                expirationDate: expirationISO,
                barcodeFormat: nil,
                serialNumber: reuseSerial
            )
            // Generate signed .pkpass first — vault only after success.
            let data = try await model.api.createPass(request)

            let displayName: String = {
                if brand.id == "airbnb", let property = pruned["property"], !property.isEmpty {
                    return property
                }
                if let event = pruned["event"], !event.isEmpty { return event }
                return brand.displayName
            }()

            let pkPass = try? PKPass(data: data)
            latestPKPass = pkPass

            // If pass-engine ignored serial reuse, adding would create a duplicate Wallet entry.
            if let expected = reuseSerial,
               let pkPass,
               pkPass.serialNumber != expected {
                errorMessage = """
                Pass engine returned a new serial instead of updating the existing Wallet pass.

                Restart pass-engine so serial reuse is active, then tap Update Pass again.
                """
                return
            }

            let inWallet = pkPass.map { PKPassLibrary().containsPass($0) } ?? false
            let linkedStillInstalled = WalletPassLink.isInstalled(serial: reuseSerial)
            alreadyInAppleWallet = inWallet || linkedStillInstalled
            passData = data
            if autoSurface, triggerMode == .geofence {
                geofence.register(fields: pruned, templateId: brand.id, displayName: displayName)
            }

            let payload = PassVaultPayload(
                templateId: brand.id,
                displayName: displayName,
                fields: pruned,
                stationIds: [],
                relevantDateISO8601: relevantISO,
                rationale: "Generated pass",
                confidence: 1,
                qrPayload: pruned["qr_data"],
                barcodeSymbology: nil,
                recognizedText: nil
            )
            if let id = vaultRecordId,
               let existing = vault.records.first(where: { $0.id == id }) {
                // Persist serial on the vault row when we intentionally reused/created one.
                if let reuseSerial,
                   (existing.walletSerialNumber ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    existing.walletSerialNumber = reuseSerial
                }
                _ = try vault.update(
                    existing,
                    payload: payload,
                    walletAdded: inWallet || linkedStillInstalled,
                    walletPass: pkPass
                )
            } else {
                let record = try vault.save(
                    payload: payload,
                    walletAdded: inWallet,
                    walletPass: pkPass
                )
                vaultRecordId = record.id
            }
            showWallet = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private var isUpdatingExistingPass: Bool {
        vaultRecordId != nil
    }

    /// Reuse PassKit serial so Wallet updates the existing pass instead of adding a duplicate.
    private func stableWalletSerial() -> String? {
        guard let id = vaultRecordId,
              let record = vault.records.first(where: { $0.id == id }) else {
            return nil
        }
        return WalletPassLink.serialForRegenerate(record: record, vaultRecords: vault.records, organizationName: WalletPassLink.organizationName(forTemplateId: brand.id))
    }

    /// Restore In Wallet badge / Update CTA from vault + PassKit on open.
    private func hydrateWalletLink() {
        guard let id = vaultRecordId,
              let record = vault.records.first(where: { $0.id == id }) else { return }
        _ = vault.syncWalletPresence()
        if let refreshed = vault.records.first(where: { $0.id == id }) {
            alreadyInAppleWallet = refreshed.walletAdded
                || WalletPassLink.isInstalled(
                    serial: refreshed.walletSerialNumber,
                    passTypeIdentifier: refreshed.walletPassTypeIdentifier
                )
            if alreadyInAppleWallet, !refreshed.walletAdded {
                try? vault.markWalletAdded(refreshed)
            }
        } else {
            alreadyInAppleWallet = record.walletAdded
        }
    }

    private var walletSheetIcon: String {
        alreadyInAppleWallet ? "wallet.pass.fill" : "checkmark.seal.fill"
    }

    private var walletSheetTint: Color {
        alreadyInAppleWallet ? SlipTheme.indigo : SlipTheme.upiGreen
    }

    private var walletSheetTitle: String {
        alreadyInAppleWallet ? "Update Apple Wallet" : "Pass ready"
    }

    private var walletSheetSubtitle: String {
        if alreadyInAppleWallet {
            return "This pass is already in Apple Wallet. Tap Update to refresh the existing Wallet pass — a new entry will not be created."
        }
        if !PKAddPassesViewController.canAddPasses() {
            return "Pass generated and sealed in your Slip vault. This device can’t open Add to Wallet."
        }
        return "Sealed in your Slip vault. Use Add to Apple Wallet to store it in PassKit — requires a signed .pkpass from pass-engine."
    }

    private func refreshWalletPresence(passData: Data) {
        guard let pass = try? PKPass(data: passData) else {
            alreadyInAppleWallet = false
            return
        }
        latestPKPass = pass
        let present = PKPassLibrary().containsPass(pass)
        alreadyInAppleWallet = present
        if present {
            markVaultWalletAdded(pass: pass)
        }
    }

    private func markVaultWalletAdded(pass: PKPass? = nil) {
        guard let vaultRecordId,
              let saved = vault.records.first(where: { $0.id == vaultRecordId }) else { return }
        try? vault.markWalletAdded(saved, pass: pass ?? latestPKPass)
        alreadyInAppleWallet = true
    }

    /// Close Wallet sheet + Pass Details (+ parent confirm sheet via callback) and return home.
    private func finishAfterWalletAdd(pass: PKPass?) {
        markVaultWalletAdded(pass: pass ?? latestPKPass)
        showWallet = false
        // Let the wallet sheet finish dismissing before popping parents.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            dismiss()
            onReturnHome?()
        }
    }
}
