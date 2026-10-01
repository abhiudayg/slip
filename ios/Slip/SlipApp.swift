import SwiftUI

@main
struct SlipApp: App {
    @StateObject private var model = AppModel()
    @StateObject private var vault = PassVaultStore()
    @StateObject private var auth = AuthSession()
    @State private var brightQR: BrightQRRequest?
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            Group {
                if auth.isSignedIn {
                    ContentView()
                        .task {
                            model.consumeSharedPayloadIfNeeded()
                            await vault.syncFromCloud()
                            vault.syncWalletPresence()
                            SlipHaptics.prepare()
                            if vault.isUnlocked {
                                await BookingReminderScheduler.reschedule(from: vault)
                                await LiveStatusService.refreshActivePasses(from: vault)
                            }
                        }
                } else {
                    LoginView()
                }
            }
            .environmentObject(model)
            .environmentObject(vault)
            .environmentObject(auth)
            .environmentObject(PassGeofenceManager.shared)
            .task {
                await auth.validatePersistedAppleSession()
            }
            .onOpenURL { url in
                model.consumeSharedPayloadIfNeeded()
                if let package = PassSharePackage.parse(from: url) {
                    model.importSharePackage(package)
                    return
                }
                if let passId = SlipDeepLink.parsePassId(from: url) {
                    brightQR = BrightQRRequest(passId: passId)
                    return
                }
                if let passId = SlipSiriHandoff.consumePendingPassId() {
                    brightQR = BrightQRRequest(passId: passId)
                }
            }
            .onChange(of: scenePhase) { _, phase in
                guard phase == .active else { return }
                Task {
                    await BookingInboxWatcher.scanClipboardIfNeeded()
                    if vault.isUnlocked {
                        await LiveStatusService.refreshActivePasses(from: vault)
                    }
                }
            }
            .fullScreenCover(item: $brightQR) { req in
                brightQRCover(req)
            }
            .onAppear {
                model.consumeSharedPayloadIfNeeded()
                if let passId = SlipSiriHandoff.consumePendingPassId() {
                    brightQR = BrightQRRequest(passId: passId)
                }
            }
        }
    }

    @ViewBuilder
    private func brightQRCover(_ req: BrightQRRequest) -> some View {
        let snap = WidgetPassStore.load().first { $0.id == req.passId }
        if let snap {
            BrightQRView(passId: snap.id, displayName: snap.displayName, payload: snap.qrPayload) {
                brightQR = nil
            }
        } else if let record = vault.records.first(where: { $0.id == req.passId }),
                  let payload = try? vault.decrypt(record) {
            let qr = payload.qrPayload ?? payload.fields["qr_data"] ?? ""
            BrightQRView(passId: record.id, displayName: record.displayName, payload: qr) {
                brightQR = nil
            }
        } else {
            VStack(spacing: 16) {
                Text("Pass QR unavailable")
                    .font(.headline)
                Text("Unlock Slip and open the pass once so its QR can sync to widgets.")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                Button("Close") { brightQR = nil }
            }
            .padding()
        }
    }
}

struct BrightQRRequest: Identifiable {
    var id: String { passId }
    let passId: String
}
