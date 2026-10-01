import SwiftUI
import UniformTypeIdentifiers

struct BrandConfirmView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.dismiss) private var dismiss

    let brand: BrandSummary
    @State var fields: [String: String]
    @State private var selectedStationIds: Set<String> = []
    @State private var relevantDate = Date().addingTimeInterval(7200)
    @State private var includeRelevantDate = false
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @State private var passData: Data?
    @State private var showAddPasses = false

    init(brand: BrandSummary, initialQR: String) {
        self.brand = brand
        var initial: [String: String] = [:]
        for key in brand.requiredFields + brand.optionalFields {
            initial[key] = ""
        }
        if !initialQR.isEmpty {
            initial["qr_data"] = initialQR
            if initialQR.lowercased().hasPrefix("upi://"),
               let name = URLComponents(string: initialQR)?
                .queryItems?
                .first(where: { $0.name == "pn" })?
                .value {
                initial["name"] = name.replacingOccurrences(of: "+", with: " ")
            }
        }
        _fields = State(initialValue: initial)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Pass") {
                    LabeledContent("Brand", value: brand.displayName)
                    LabeledContent("Style", value: brand.appleStyle)
                }

                Section("Details") {
                    ForEach(brand.requiredFields + brand.optionalFields, id: \.self) { key in
                        if key == "origin" || key == "destination" {
                            stationPicker(field: key)
                        } else {
                            TextField(label(for: key), text: binding(for: key), axis: key == "qr_data" ? .vertical : .horizontal)
                                .textInputAutocapitalization(key == "qr_data" ? .never : .words)
                                .font(key == "qr_data" ? .footnote.monospaced() : .body)
                        }
                    }
                }

                if brand.supportsLocations && brand.stationCatalog != nil {
                    Section("Lock screen stations (max 10)") {
                        ForEach(model.stations) { station in
                            Toggle(isOn: Binding(
                                get: { selectedStationIds.contains(station.id) },
                                set: { on in
                                    if on {
                                        if selectedStationIds.count < 10 { selectedStationIds.insert(station.id) }
                                    } else {
                                        selectedStationIds.remove(station.id)
                                    }
                                }
                            )) {
                                VStack(alignment: .leading) {
                                    Text(station.name)
                                    Text(station.line).font(.caption).foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }

                if brand.supportsRelevantDate {
                    Section("Time relevance") {
                        Toggle("Surface before event", isOn: $includeRelevantDate)
                        if includeRelevantDate {
                            DatePicker("Show around", selection: $relevantDate)
                        }
                    }
                }

                Section {
                    Button {
                        Task { await createPass() }
                    } label: {
                        if isSubmitting {
                            ProgressView()
                        } else {
                            Text("Generate pass")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .disabled(isSubmitting || !canSubmit)
                }
            }
            .navigationTitle(brand.displayName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .alert("Couldn’t create pass", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "")
            }
            .sheet(isPresented: $showAddPasses) {
                NavigationStack {
                    VStack(spacing: 20) {
                        Text("Pass ready")
                            .font(.title2.weight(.semibold))
                        Text("Add it to Wallet, then double-click the Side Button to present.")
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.secondary)
                        if let passData {
                            AddToWalletButton(passData: passData) { _ in
                                showAddPasses = false
                                dismiss()
                            }
                        }
                        ShareLink(item: PassFile(data: passData ?? Data()), preview: SharePreview("slip.pkpass")) {
                            Label("Share .pkpass file", systemImage: "square.and.arrow.up")
                        }
                        .disabled(passData == nil)
                    }
                    .padding()
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Done") {
                                showAddPasses = false
                                dismiss()
                            }
                        }
                    }
                }
            }
        }
    }

    private struct PassFile: Transferable {
        let data: Data
        static var transferRepresentation: some TransferRepresentation {
            DataRepresentation(exportedContentType: .data) { file in
                file.data
            }
        }
    }

    private var canSubmit: Bool {
        brand.requiredFields.allSatisfy { key in
            !(fields[key] ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    private func binding(for key: String) -> Binding<String> {
        Binding(
            get: { fields[key] ?? "" },
            set: { fields[key] = $0 }
        )
    }

    @ViewBuilder
    private func stationPicker(field: String) -> some View {
        Picker(label(for: field), selection: binding(for: field)) {
            Text("Select").tag("")
            ForEach(model.stations) { station in
                Text(station.name).tag(station.name)
            }
        }
    }

    private func label(for key: String) -> String {
        switch key {
        case "qr_data": return "QR / barcode payload"
        case "booking_id": return "Booking ID"
        default: return key.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }

    private func createPass() async {
        isSubmitting = true
        defer { isSubmitting = false }
        do {
            var request = CreatePassRequest(
                template: brand.id,
                fields: fields.mapValues { $0.trimmingCharacters(in: .whitespacesAndNewlines) },
                locations: nil,
                stationIds: selectedStationIds.isEmpty ? nil : Array(selectedStationIds),
                relevantDate: nil,
                expirationDate: nil,
                barcodeFormat: nil,
                serialNumber: nil
            )
            if includeRelevantDate {
                let formatter = ISO8601DateFormatter()
                formatter.formatOptions = [.withInternetDateTime]
                request.relevantDate = formatter.string(from: relevantDate)
                let expires = relevantDate.addingTimeInterval(6 * 3600)
                request.expirationDate = formatter.string(from: expires)
            }
            let hash = PkpassCache.contentHash(templateId: brand.id, fields: fields, serial: nil)
            let data: Data
            do {
                data = try await model.api.createPass(request)
                PkpassCache.store(recordId: "confirm-\(brand.id)", hash: hash, data: data)
            } catch {
                if let cached = PkpassCache.load(recordId: "confirm-\(brand.id)", hash: hash) {
                    data = cached
                } else {
                    throw error
                }
            }
            passData = data
            showAddPasses = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

