import SwiftUI

@main
struct SlipAppClipApp: App {
    @StateObject private var model = AppClipModel()

    var body: some Scene {
        WindowGroup {
            AppClipRootView()
                .environmentObject(model)
                .onOpenURL { url in
                    model.consume(url: url)
                }
                .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { activity in
                    if let url = activity.webpageURL {
                        model.consume(url: url)
                    }
                }
        }
    }
}
