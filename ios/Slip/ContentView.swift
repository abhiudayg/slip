import PhotosUI
import SwiftUI
import UniformTypeIdentifiers

/// Root shell — wires Stitch artboards 1–5 with floating dock.
struct ContentView: View {
    @EnvironmentObject private var model: AppModel
    @EnvironmentObject private var vault: PassVaultStore
    @State private var tab: FloatingDock.Tab = .home
    @State private var showScanner = false
    @State private var selectedBrand: BrandSummary?
    @State private var photoItem: PhotosPickerItem?
    @State private var showPhotoPicker = false
    @State private var showFileImporter = false
    @State private var showImportMenu = false

    var body: some View {
        ZStack {
            MeshBackground()

            Group {
                switch tab {
                case .home:
                    DashboardView(
                        onOpenSettings: { tab = .settings },
                        onOpenMarketplace: { tab = .marketplace },
                        onSelectBrand: { selectedBrand = $0 }
                    )
                case .marketplace:
                    MarketplaceView(
                        onSelectBrand: { selectedBrand = $0 },
                        onScanScreenshot: { showImportMenu = true }
                    )
                case .settings:
                    SettingsView(onDone: { tab = .home })
                }
            }

            VStack {
                Spacer()
                FloatingDock(
                    tab: $tab,
                    onCamera: { showImportMenu = true },
                    onScan: { showScanner = true },
                    onNewPass: { tab = .marketplace }
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 10)
            }
        }
        .preferredColorScheme(.dark)
        .task { await model.bootstrap() }
        .sheet(item: $selectedBrand) { brand in
            PassDetailsView(brand: brand)
                .environmentObject(model)
                .environmentObject(vault)
        }
        .sheet(item: $model.pendingClassification) { classification in
            ConfirmPassSheet(classification: classification)
                .environmentObject(model)
                .environmentObject(vault)
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
        }
        .fullScreenCover(isPresented: $showScanner) {
            LiveScannerView { message, symbology in
                showScanner = false
                model.classifyScanned(payload: message, symbology: symbology)
            } onCancel: {
                showScanner = false
            }
        }
        .confirmationDialog("Import ticket", isPresented: $showImportMenu, titleVisibility: .visible) {
            Button("Photo / screenshot") {
                // Defer so we don't publish while the dialog dismisses.
                Task { @MainActor in
                    await Task.yield()
                    showPhotoPicker = true
                }
            }
            Button("PDF booking") {
                Task { @MainActor in
                    await Task.yield()
                    showFileImporter = true
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Share a screenshot or booking PDF to extract QR and fields.")
        }
        .photosPicker(isPresented: $showPhotoPicker, selection: $photoItem, matching: .images)
        .onChange(of: photoItem) { _, item in
            guard let item else { return }
            Task { @MainActor in
                // Leave the PhotosPicker binding update before publishing AppModel state.
                await Task.yield()
                defer { photoItem = nil }
                if let data = try? await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    await model.classifyImage(image)
                }
            }
        }
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: [.pdf],
            allowsMultipleSelection: false
        ) { result in
            Task { @MainActor in
                await Task.yield()
                switch result {
                case .success(let urls):
                    guard let url = urls.first else { return }
                    let accessing = url.startAccessingSecurityScopedResource()
                    defer { if accessing { url.stopAccessingSecurityScopedResource() } }
                    do {
                        let data = try Data(contentsOf: url)
                        await model.classifyPDF(data)
                    } catch {
                        model.errorMessage = error.localizedDescription
                    }
                case .failure(let error):
                    model.errorMessage = error.localizedDescription
                }
            }
        }
        .alert("Something went wrong", isPresented: Binding(
            get: { model.errorMessage != nil },
            set: { clear in
                guard clear == false else { return }
                Task { @MainActor in
                    model.errorMessage = nil
                }
            }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(model.errorMessage ?? "")
        }
        .overlay {
            if model.isLoadingBrands || model.isExtracting {
                ProgressView(model.isExtracting ? "Reading ticket…" : "Loading…")
                    .padding(20)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
    }
}
