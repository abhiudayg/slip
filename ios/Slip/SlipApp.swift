import SwiftUI

@main
struct SlipApp: App {
    @StateObject private var model = AppModel()
    @StateObject private var vault = PassVaultStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(model)
                .environmentObject(vault)
                .task {
                    model.consumeSharedPayloadIfNeeded()
                    await vault.syncFromCloud()
                }
                .onOpenURL { _ in
                    model.consumeSharedPayloadIfNeeded()
                }
                .onAppear {
                    model.consumeSharedPayloadIfNeeded()
                }
        }
    }
}
