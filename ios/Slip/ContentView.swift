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
                        onScanScreenshot: { showScanner = true },
                        onImportPDF: {
                            Task { @MainActor in
                                await Task.yield()
                                showFileImporter = true
                            }
                        }
                    )
                case .settings:
                    SettingsView(onDone: { tab = .home })
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                FloatingDock(
                    tab: $tab,
                    onScan: { showScanner = true },
                    onNewPass: {
                        withAnimation(.spring(response: 0.45, dampingFraction: 0.86)) {
                            showImportMenu = true
                        }
                    },
                    onImport: {
                        withAnimation(.spring(response: 0.45, dampingFraction: 0.86)) {
                            showImportMenu = true
                        }
                    }
                )
                .frame(maxWidth: .infinity)
                .padding(.bottom, 8)
            }

            if showImportMenu {
                ImportTicketMenu(
                    isPresented: $showImportMenu,
                    onScan: { showScanner = true },
                    onPhoto: { showPhotoPicker = true },
                    onPDF: { showFileImporter = true },
                    onTemplates: { tab = .marketplace }
                )
                .transition(.opacity)
                .zIndex(10)
            }
        }
        .animation(.easeOut(duration: 0.2), value: showImportMenu)
        .preferredColorScheme(.dark)
        .task { await model.bootstrap() }
        .sheet(item: $selectedBrand) { brand in
            PassDetailsView(
                brand: brand,
                onReturnHome: {
                    selectedBrand = nil
                    tab = .home
                }
            )
            .environmentObject(model)
            .environmentObject(vault)
            .environmentObject(PassGeofenceManager.shared)
        }
        .sheet(item: $model.pendingImport) { pending in
            BrandSelectSheet(pending: pending)
                .environmentObject(model)
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
                .interactiveDismissDisabled(false)
        }
        .sheet(item: $model.pendingClassification) { classification in
            ConfirmPassSheet(classifications: [classification])
                .environmentObject(model)
                .environmentObject(vault)
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
        }
        .sheet(item: $model.pendingBatch) { batch in
            ConfirmPassSheet(classifications: batch.items)
                .environmentObject(model)
                .environmentObject(vault)
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
        }
        .fullScreenCover(isPresented: $showScanner) {
            LiveScannerView(
                onCode: { message, symbology in
                    showScanner = false
                    model.classifyScanned(payload: message, symbology: symbology)
                },
                onImage: { image in
                    showScanner = false
                    Task { await model.classifyImage(image) }
                },
                onPDF: { data in
                    showScanner = false
                    Task { await model.classifyPDF(data) }
                },
                onCancel: {
                    showScanner = false
                }
            )
        }
        .photosPicker(isPresented: $showPhotoPicker, selection: $photoItem, matching: .images)
        .onChange(of: photoItem) { _, item in
            guard let item else { return }
            Task { @MainActor in
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
                ZStack {
                    // Fully obscure vault cards / pass data while work is in flight.
                    SlipTheme.canvasDeep.opacity(0.92)
                        .ignoresSafeArea()
                    MeshBackground()
                        .opacity(0.55)
                        .ignoresSafeArea()
                        .allowsHitTesting(false)

                    VStack(spacing: 18) {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(SlipTheme.accentSoft)
                            .scaleEffect(1.25)

                        Text(model.isExtracting ? model.extractingStatus : "Syncing Slip")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(SlipTheme.ink)

                        Text(model.isExtracting
                             ? (model.extractingStatus == "Extracting pass fields"
                                ? "Running brand extraction and on-device fill…"
                                : "Reading your screenshot or PDF on-device…")
                             : "Refreshing templates and vault status…")
                            .font(.caption)
                            .foregroundStyle(SlipTheme.muted)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 28)
                    }
                    .padding(.horizontal, 28)
                    .padding(.vertical, 32)
                    .frame(maxWidth: 320)
                    .background {
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(SlipTheme.card.opacity(0.95))
                            .overlay(
                                RoundedRectangle(cornerRadius: 24, style: .continuous)
                                    .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
                            )
                            .shadow(color: .black.opacity(0.45), radius: 28, y: 12)
                    }
                }
                .transition(.opacity)
                .accessibilityElement(children: .combine)
                .accessibilityLabel(model.isExtracting ? model.extractingStatus : "Loading")
            }
        }
        .animation(.easeInOut(duration: 0.2), value: model.isLoadingBrands || model.isExtracting)
    }
}
