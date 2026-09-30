import SwiftUI

@main
struct SlipApp: App {
    @StateObject private var model = AppModel()
    @StateObject private var vault = PassVaultStore()
    @StateObject private var auth = AuthSession()

    var body: some Scene {
        WindowGroup {
            Group {
                if auth.isSignedIn {
                    ContentView()
                        .task {
                            model.consumeSharedPayloadIfNeeded()
                            await vault.syncFromCloud()
                            vault.syncWalletPresence()
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
            .onOpenURL { _ in
                model.consumeSharedPayloadIfNeeded()
            }
            .onAppear {
                model.consumeSharedPayloadIfNeeded()
            }
        }
    }
}
