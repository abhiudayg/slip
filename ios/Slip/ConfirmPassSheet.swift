import SwiftUI
import PassKit

/// Artboard 3 — AI Screenshot Scanner & Auto-Detection Modal
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

    private var isMultiTraveler: Bool { classifications.count > 1 }

    private var classification: ClassificationResult {
        classifications[min(max(selectedIndex, 0), max(classifications.count - 1, 0))]
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

    var body: some View {
        ZStack {
            MeshBackground()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    topBar
                    neuralHeader
                    if isMultiTraveler {
                        travelerBatchCard
                    }
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
            NavigationStack {
                Form {
                    let schema = BrandFields.schema(for: classification.templateId.isEmpty ? (resolvedBrand?.id ?? "") : classification.templateId)
                    Section {
                        ForEach(schema.required, id: \.self) { key in
                            LabeledContent(label(for: key)) {
                                TextField(label(for: key), text: binding(for: key), axis: key == "qr_data" ? .vertical : .horizontal)
                                    .multilineTextAlignment(.trailing)
                                    .textInputAutocapitalization(.never)
                            }
                        }
                    } header: {
                        Text("Required · \(classification.templateId.isEmpty ? "Pass" : classification.templateId)")
                    } footer: {
                        Text("Only fields for this brand. Extra keys like PNR are omitted for UPI/event tickets.")
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
    }

    private var topBar: some View {
        HStack {
            Button {
                model.clearPendingClassification()
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
        WalletPassPreview(
            brandId: classification.templateId.isEmpty ? "upi" : classification.templateId,
            displayName: classification.displayName.isEmpty ? "Detected Pass" : classification.displayName,
            fields: fieldsBinding,
            accentRGB: resolvedBrand?.accentHint,
            editable: true
        )
    }

    private var fieldsBinding: Binding<[String: String]> {
        Binding(
            get: { classification.fields },
            set: { newValue in
                updateClassification { $0.fields = newValue }
            }
        )
    }


    private var previewFooterRow: some View {
        HStack(spacing: 8) {
            Label(previewSecondaryLabel, systemImage: previewSecondaryIcon)
                .font(.caption.weight(.semibold))
                .foregroundStyle(SlipTheme.ink)
                .lineLimit(1)
            Spacer(minLength: 8)
            if isRouteStyle {
                Text(value(["seat", "coach"], "Seat pending"))
                    .font(.caption)
                    .foregroundStyle(SlipTheme.muted)
            } else if classification.templateId == "airbnb" {
                let guests = value(["guest"], "")
                if !guests.isEmpty {
                    Text(guests)
                        .font(.caption)
                        .foregroundStyle(SlipTheme.muted)
                        .lineLimit(1)
                }
            } else if isEventStyle {
                Text(value(["seat"], "—"))
                    .font(.caption)
                    .foregroundStyle(SlipTheme.muted)
            }
            qrStatusPill
        }
    }

    @ViewBuilder
    private var qrStatusPill: some View {
        let qr = value(["qr_data"], "")
        if qr.isEmpty {
            StatusPill(title: "No QR", tint: SlipTheme.muted)
        } else {
            StatusPill(title: "2D QR OK", tint: SlipTheme.upiGreen)
        }
    }

    private var airbnbPreviewBody: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 6) {
                TextField("Property", text: binding(for: "property"))
                    .font(.title3.weight(.bold))
                    .foregroundStyle(SlipTheme.ink)
                    .lineLimit(3)
                Image(systemName: "pencil")
                    .font(.caption2)
                    .foregroundStyle(SlipTheme.muted.opacity(0.45))
                    .padding(.top, 6)
            }
            HStack(spacing: 12) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.down.to.line")
                        .foregroundStyle(SlipTheme.accentSoft)
                    TextField("Check-in", text: binding(for: "check_in"))
                        .font(.caption.weight(.medium))
                        .foregroundStyle(SlipTheme.accentSoft)
                        .lineLimit(1)
                }
                HStack(spacing: 4) {
                    Image(systemName: "arrow.up.to.line")
                        .foregroundStyle(SlipTheme.accentSoft)
                    TextField("Check-out", text: binding(for: "check_out"))
                        .font(.caption.weight(.medium))
                        .foregroundStyle(SlipTheme.accentSoft)
                        .lineLimit(1)
                }
            }
        }
    }

    private var eventPreviewBody: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 6) {
                TextField("Event / movie", text: binding(for: "event"))
                    .font(.title3.weight(.bold))
                    .foregroundStyle(SlipTheme.ink)
                    .lineLimit(2)
                Image(systemName: "pencil")
                    .font(.caption2)
                    .foregroundStyle(SlipTheme.muted.opacity(0.45))
                    .padding(.top, 6)
            }
            HStack(spacing: 6) {
                Image(systemName: "mappin.and.ellipse")
                    .foregroundStyle(SlipTheme.muted)
                TextField("Venue", text: binding(for: "venue"))
                    .font(.subheadline)
                    .foregroundStyle(SlipTheme.muted)
            }
            HStack(spacing: 12) {
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .foregroundStyle(SlipTheme.accentSoft)
                    TextField("Showtime", text: binding(for: "time"))
                        .font(.caption.weight(.medium))
                        .foregroundStyle(SlipTheme.accentSoft)
                }
                HStack(spacing: 4) {
                    Image(systemName: "chair.lounge.fill")
                        .foregroundStyle(SlipTheme.accentSoft)
                    TextField("Seat", text: binding(for: "seat"))
                        .font(.caption.weight(.medium))
                        .foregroundStyle(SlipTheme.accentSoft)
                }
            }
        }
    }

    private var routePreviewBody: some View {
        HStack {
            routeBlock(timeKey: "dep", placeKey: "origin", placeholder: "Origin")
            VStack(spacing: 4) {
                Image(systemName: "arrow.right")
                    .foregroundStyle(SlipTheme.accentSoft)
                TextField("Dur", text: binding(for: "duration"))
                    .font(.caption2)
                    .foregroundStyle(SlipTheme.muted)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            routeBlock(timeKey: "arr", placeKey: "destination", placeholder: "Destination")
        }
    }

    private var genericPreviewBody: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top, spacing: 6) {
                TextField("Title", text: binding(for: genericPrimaryKey))
                    .font(.title3.weight(.bold))
                    .foregroundStyle(SlipTheme.ink)
                Image(systemName: "pencil")
                    .font(.caption2)
                    .foregroundStyle(SlipTheme.muted.opacity(0.45))
                    .padding(.top, 6)
            }
            Text(classification.rationale)
                .font(.caption)
                .foregroundStyle(SlipTheme.muted)
                .lineLimit(2)
        }
    }

    private var genericPrimaryKey: String {
        for key in ["name", "event", "restaurant", "property", "vehicle"] {
            if let v = classification.fields[key], !v.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return key
            }
        }
        switch classification.templateId {
        case "upi": return "name"
        case "zoomcar": return "vehicle"
        case "airbnb": return "property"
        default: return "name"
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
                if isDiningStyle {
                    summaryRow("Restaurant", key: "restaurant", icon: "fork.knife", placeholder: "Restaurant name")
                    rowDivider
                    summaryRow("Time", key: "time", icon: "clock.fill", placeholder: "Date & time")
                    rowDivider
                    summaryRow("Guests", key: "party_size", icon: "person.2.fill", placeholder: "Party size")
                    rowDivider
                    summaryRow("Booking", key: "booking_id", icon: "number", placeholder: "Booking ID")
                } else if classification.templateId == "zoomcar" {
                    summaryRow("Vehicle", key: "vehicle", icon: "car.fill", placeholder: "Vehicle")
                    rowDivider
                    summaryRow("Pickup", key: "pickup", icon: "mappin.and.ellipse", placeholder: "Pickup")
                    rowDivider
                    summaryRow("Drop-off", key: "drop_off", icon: "flag.checkered", placeholder: "Drop-off")
                    rowDivider
                    summaryRow("Guest", key: "guest", icon: "person.fill", placeholder: "Guest name")
                    rowDivider
                    summaryRow("Booking", key: "booking_id", icon: "number", placeholder: "Booking ID")
                } else if isEventStyle {
                    summaryRow("Event", key: "event", icon: "ticket.fill", placeholder: "Event / movie")
                    rowDivider
                    summaryRow("Venue", key: "venue", icon: "building.2.fill", placeholder: "Venue")
                    rowDivider
                    summaryRow("Showtime", key: "time", icon: "clock.fill", placeholder: "Showtime")
                    rowDivider
                    summaryRow("Seat", key: "seat", icon: "chair.lounge.fill", placeholder: "Seat")
                    rowDivider
                    summaryRow("Booking", key: "booking_id", icon: "number", placeholder: "Booking ID")
                } else if classification.templateId == "airbnb" {
                    summaryRow("Property", key: "property", icon: "house.fill", placeholder: "Property")
                    rowDivider
                    summaryRow("Stay type", key: "property_type", icon: "building.2.fill", placeholder: "Entire home")
                    rowDivider
                    summaryRow("Check-in", key: "check_in", icon: "arrow.down.to.line", placeholder: "Check-in date")
                    rowDivider
                    summaryRow("Check-in time", key: "check_in_time", icon: "clock", placeholder: "After 1:00 PM")
                    rowDivider
                    summaryRow("Check-out", key: "check_out", icon: "arrow.up.to.line", placeholder: "Check-out date")
                    rowDivider
                    summaryRow("Check-out time", key: "check_out_time", icon: "clock", placeholder: "By 11:00 AM")
                    rowDivider
                    summaryRow("Guests", key: "guest", icon: "person.2.fill", placeholder: "Guests")
                    rowDivider
                    summaryRow("Door PIN", key: "door_pin", icon: "lock.fill", placeholder: "Backup door PIN")
                    rowDivider
                    summaryRow("Reservation", key: "booking_id", icon: "number", placeholder: "Reservation code")
                    rowDivider
                    summaryRow("QR / barcode", key: "qr_data", icon: "qrcode", placeholder: "QR payload")
                } else if classification.templateId == "upi" {
                    summaryRow("Payee", key: "name", icon: "person.fill", placeholder: "Payee name")
                    rowDivider
                    summaryRow("UPI / QR", key: "qr_data", icon: "qrcode", placeholder: "upi://…")
                } else if isRouteStyle {
                    summaryRow("Origin", key: "origin", icon: "mappin.and.ellipse", placeholder: "Origin")
                    rowDivider
                    summaryRow("Destination", key: "destination", icon: "location.fill", placeholder: "Destination")
                    rowDivider
                    if classification.templateId == "indigo" {
                        summaryRow("Flight", key: "flight", icon: "airplane", placeholder: "Flight")
                    } else if classification.templateId == "redbus" {
                        summaryRow("Bus", key: "bus", icon: "bus.fill", placeholder: "Bus")
                    } else if classification.templateId != "namma-metro" {
                        summaryRow("Train", key: "train", icon: "train.side.front.car", placeholder: "Train")
                    }
                    if classification.templateId == "indigo" || classification.templateId == "redbus" || classification.templateId == "irctc" {
                        rowDivider
                        summaryRow("Seat", key: "seat", icon: "chair.lounge.fill", placeholder: "Seat")
                    }
                    if classification.templateId == "irctc" {
                        rowDivider
                        summaryRow("Coach", key: "coach", icon: "square.grid.3x3.fill", placeholder: "Coach")
                    }
                    rowDivider
                    summaryRow("Departure", key: "dep", icon: "clock.fill", placeholder: "Departure")
                } else {
                    ForEach(Array(editableKeys.prefix(6)), id: \.self) { key in
                        summaryRow(label(for: key), key: key, icon: "text.alignleft", placeholder: label(for: key))
                        if key != editableKeys.prefix(6).last {
                            rowDivider
                        }
                    }
                }

                rowDivider
                summaryRow("Location", key: "location", icon: "location.fill", placeholder: "Venue, address, or lat, lon")
            }
        }
    }


    private var isDiningStyle: Bool {
        ["easydiner", "zomato-dineout", "swiggy-dineout"].contains(classification.templateId)
            || resolvedBrand?.category == "dining"
    }

    private var isEventStyle: Bool {
        if isDiningStyle { return false }
        let id = classification.templateId
        return id == "bookmyshow" || id == "district"
            || resolvedBrand?.appleStyle == "eventTicket"
            || resolvedBrand?.category == "entertainment"
    }

    private var isRouteStyle: Bool {
        if classification.templateId == "zoomcar" { return false }
        let id = classification.templateId
        return ["irctc", "indigo", "namma-metro", "redbus"].contains(id)
            || resolvedBrand?.appleStyle == "boardingPass"
    }

    private var previewIcon: String {
        switch classification.templateId {
        case "bookmyshow", "district": return "ticket.fill"
        case "indigo": return "airplane"
        case "namma-metro": return "tram.fill"
        case "upi": return "qrcode"
        case "redbus": return "bus.fill"
        case "airbnb": return "house.fill"
        case "zoomcar": return "car.fill"
        case "easydiner", "zomato-dineout", "swiggy-dineout": return "fork.knife"
        default: return isEventStyle ? "ticket.fill" : (isRouteStyle ? "train.side.front.car" : "ticket.fill")
        }
    }

    private var previewTint: Color {
        switch classification.templateId {
        case "airbnb": return Color(red: 1.0, green: 0.35, blue: 0.45)
        case "bookmyshow": return SlipTheme.magenta
        case "district": return Color(red: 0.49, green: 0.23, blue: 0.93)
        default: return isEventStyle ? SlipTheme.magenta : SlipTheme.indigo
        }
    }

    private var previewIdLabel: String {
        let style = BrandFields.previewStyle(
            for: classification.templateId,
            appleStyle: resolvedBrand?.appleStyle
        )
        switch style {
        case .event:
            return "Booking: \(value(["booking_id"], "—"))"
        case .upi:
            return "UPI: \(value(["name"], "—"))"
        case .route:
            return "PNR: \(value(["pnr", "booking_id"], "—"))"
        case .generic:
            return BrandFields.idCaption(for: classification.templateId) + ": \(value(["booking_id", "name"], "—"))"
        }
    }

    private var previewSecondaryLabel: String {
        if classification.templateId == "district" {
            return value(["event", "venue"], "Festival Pass")
        }
        if classification.templateId == "zoomcar" {
            return value(["vehicle", "pickup"], classification.displayName)
        }
        if isDiningStyle {
            return value(["restaurant", "time"], classification.displayName)
        }
        if isEventStyle {
            return value(["event"], "Movie Ticket")
        }
        if classification.templateId == "airbnb" {
            return value(["guest"], "Guests")
        }
        if isRouteStyle {
            return value(["passenger", "name"], "Passenger")
        }
        return value(["name", "guest", "restaurant", "vehicle"], classification.displayName)
    }

    private var previewSecondaryIcon: String {
        if classification.templateId == "district" { return "bolt.fill" }
        if isDiningStyle { return "fork.knife" }
        if isEventStyle { return "film" }
        if classification.templateId == "airbnb" { return "person.2.fill" }
        if isRouteStyle { return "person.fill" }
        return "info.circle.fill"
    }

    private func optionalValue(_ keys: [String]) -> String? {
        let v = value(keys, "")
        return v.isEmpty ? nil : v
    }

    private var liveActivityToggle: some View {
        GlassCard(cornerRadius: 18, padding: 14) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "rectangle.on.rectangle.angled")
                    .foregroundStyle(SlipTheme.accentSoft)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Dynamic Island Live Activity")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(SlipTheme.ink)
                    Text(PassLiveActivityController.areActivitiesEnabled
                         ? "Shows this pass on Lock Screen and Dynamic Island after you generate it."
                         : "Live Activities are disabled in iOS Settings → Slip. Turn them on to use Dynamic Island.")
                        .font(.caption)
                        .foregroundStyle(SlipTheme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 8)
                Toggle("", isOn: $preferLiveActivity)
                    .labelsHidden()
                    .tint(SlipTheme.indigo)
            }
        }
    }

    private var travelerBatchCard: some View {
        GlassCard(cornerRadius: 18, padding: 14) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label("\(classifications.count) travelers detected", systemImage: "person.3.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(SlipTheme.ink)
                    Spacer()
                    Text("Separate passes")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(SlipTheme.accentSoft)
                }
                Text("Each passenger gets their own Slip vault pass and Apple Wallet entry (seat / coach / boarding stub).")
                    .font(.caption)
                    .foregroundStyle(SlipTheme.muted)
                ForEach(Array(classifications.enumerated()), id: \.offset) { index, item in
                    Button {
                        selectedIndex = index
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: selectedIndex == index ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(selectedIndex == index ? SlipTheme.upiGreen : SlipTheme.muted)
                            VStack(alignment: .leading, spacing: 2) {
                                Text((item.fields["passenger"]?.trimmingCharacters(in: .whitespacesAndNewlines)).flatMap { $0.isEmpty ? nil : $0 } ?? "Passenger \(index + 1)")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(SlipTheme.ink)
                                Text(travelerSubtitle(item))
                                    .font(.caption2)
                                    .foregroundStyle(SlipTheme.muted)
                            }
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func travelerSubtitle(_ item: ClassificationResult) -> String {
        let coach = item.fields["coach"]?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let seat = item.fields["seat"]?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let flight = item.fields["flight"]?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        var parts: [String] = []
        if !flight.isEmpty { parts.append(flight) }
        if !coach.isEmpty && !seat.isEmpty { parts.append("\(coach)/\(seat)") }
        else if !seat.isEmpty { parts.append("Seat \(seat)") }
        else if !coach.isEmpty { parts.append("Coach \(coach)") }
        if parts.isEmpty { return item.displayName }
        return parts.joined(separator: " · ")
    }

    private var primaryActions: some View {
        VStack(spacing: 10) {
            if let batchStatus {
                Text(batchStatus)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(SlipTheme.accentSoft)
            }
            if let batchError {
                Text(batchError)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }

            Button {
                if isMultiTraveler {
                    Task { await createAllTravelerPasses() }
                } else {
                    updateClassification { $0 = IntelligentBrandClassifier.enrich($0) }
                    ensureEditableKeys()
                    continueToPassDetails()
                }
            } label: {
                HStack {
                    if isCreatingBatch {
                        ProgressView().tint(.black)
                    }
                    Label(
                        isMultiTraveler
                            ? "Create \(classifications.count) Separate Passes"
                            : "Generate Pass with Apple AI",
                        systemImage: isMultiTraveler ? "rectangle.stack.badge.person.crop" : "sparkles"
                    )
                    .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .foregroundStyle(.black)
                .background(Capsule().fill(Color.white))
            }
            .buttonStyle(.plain)
            .disabled(isCreatingBatch)

            if isMultiTraveler {
                Button {
                    updateClassification { $0 = IntelligentBrandClassifier.enrich($0) }
                    ensureEditableKeys()
                    continueToPassDetails()
                } label: {
                    Label("Customize selected traveler", systemImage: "slider.horizontal.3")
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
                .disabled(isCreatingBatch)
            }

            Button {
                ensureEditableKeys()
                showManualEdit = true
            } label: {
                Label(isMultiTraveler ? "Edit selected fields" : "Edit Pass Fields", systemImage: "pencil.line")
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
            .disabled(isCreatingBatch)
        }
    }

    private var privacyFooter: some View {
        Label("Processed locally · Slip · On-Device", systemImage: "lock.fill")
            .font(.caption2)
            .foregroundStyle(SlipTheme.muted)
            .frame(maxWidth: .infinity)
    }

    private func routeBlock(timeKey: String, placeKey: String, placeholder: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            TextField("Time", text: binding(for: timeKey))
                .font(.title3.weight(.bold).monospacedDigit())
                .foregroundStyle(SlipTheme.ink)
            Text(abbreviate(value([placeKey], "—")))
                .font(.caption.weight(.bold))
                .foregroundStyle(SlipTheme.accentSoft)
            TextField(placeholder, text: binding(for: placeKey))
                .font(.caption2)
                .foregroundStyle(SlipTheme.muted)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// Stitch artboard: every info-bearing row is inline-editable.
    private func summaryRow(_ title: String, key: String, icon: String, placeholder: String = "") -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(SlipTheme.accentSoft)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption2)
                    .foregroundStyle(SlipTheme.muted)
                TextField(placeholder.isEmpty ? title : placeholder, text: binding(for: key), axis: key == "qr_data" ? .vertical : .horizontal)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(SlipTheme.ink)
                    .textInputAutocapitalization(key == "qr_data" ? .never : .sentences)
                    .disableAutocorrection(key == "qr_data" || key == "booking_id" || key == "pnr" || key == "seat")
            }
            Spacer(minLength: 0)
            Image(systemName: "pencil")
                .font(.caption2)
                .foregroundStyle(SlipTheme.muted.opacity(0.45))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
    }

    private var rowDivider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.08))
            .frame(height: 0.5)
            .padding(.leading, 48)
    }

    private var editableKeys: [String] {
        if let brand = resolvedBrand {
            return BrandFields.schema(for: brand.id).all
        }
        return BrandFields.schema(for: classification.templateId).all
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
            category: synthesizedCategory,
            appleStyle: synthesizedAppleStyle,
            requiredFields: Array(classification.fields.keys),
            optionalFields: [],
            supportsLocations: true,
            supportsRelevantDate: true,
            accentHint: synthesizedAccent,
            stationCatalog: nil,
            summary: nil,
            badge: synthesizedBadge,
            iconHint: previewIcon
        )
    }

    private var synthesizedCategory: String {
        switch classification.templateId {
        case "bookmyshow", "district": return "entertainment"
        case "upi": return "everyday_pay"
        case "indigo", "irctc", "namma-metro", "redbus": return "transit"
        case "easydiner", "zomato-dineout", "swiggy-dineout": return "dining"
        default: return "transit"
        }
    }

    private var synthesizedAppleStyle: String {
        switch classification.templateId {
        case "bookmyshow", "district": return "eventTicket"
        case "upi", "easydiner", "zomato-dineout", "swiggy-dineout": return "storeCard"
        case "zoomcar": return "generic"
        case "airbnb": return "storeCard"
        default: return "boardingPass"
        }
    }

    private var synthesizedAccent: String {
        switch classification.templateId {
        case "bookmyshow": return "rgb(220, 38, 38)"
        case "district": return "rgb(124, 58, 237)"
        default: return "rgb(94, 92, 230)"
        }
    }

    private var synthesizedBadge: String {
        switch classification.templateId {
        case "district": return "Festival"
        default: return isEventStyle ? "Event" : "Scan"
        }
    }

    private var coachSeatDisplay: String {
        let coach = classification.fields["coach"]?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let seat = classification.fields["seat"]?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !coach.isEmpty, !seat.isEmpty { return "\(coach)/\(seat)" }
        if !seat.isEmpty { return seat }
        if !coach.isEmpty { return coach }
        return "—"
    }

    private var pnrDisplay: String {
        value(["pnr", "booking_id"], "—")
    }

    private func routeTime(keys: [String], fallbackISO: Bool) -> String {
        let direct = value(keys, "")
        if !direct.isEmpty {
            // Prefer bare HH:mm for route chips when value is "date · time".
            if let clock = direct.split(separator: "·").map({ $0.trimmingCharacters(in: .whitespaces) }).last,
               clock.contains(":"), clock.count <= 5 {
                return String(clock)
            }
            if direct.contains(":") && direct.count <= 5 { return direct }
            return direct
        }
        if fallbackISO, let iso = classification.relevantDateISO8601 {
            // Extract HH:mm from ISO if present.
            if let regex = try? NSRegularExpression(pattern: #"T(\d{2}:\d{2})"#),
               let match = regex.firstMatch(in: iso, range: NSRange(iso.startIndex..<iso.endIndex, in: iso)),
               let r = Range(match.range(at: 1), in: iso) {
                return String(iso[r])
            }
        }
        return "—"
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

    /// Create one vault + signed .pkpass per traveler (IRCTC party / IndiGo multi-stub).
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
            try? await Task.sleep(nanoseconds: 450_000_000)
            model.clearPendingClassification()
            dismiss()
        } catch {
            batchError = error.localizedDescription
            batchStatus = nil
        }
    }

    /// Continue to pass details (vault save happens only after a signed .pkpass is generated).
    private func continueToPassDetails() {
        if preferLiveActivity {
            _ = PassLiveActivityController.start(from: classification)
        }

        // Register geofences when Always is already granted (prompt lives in Settings / Pass Details).
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
