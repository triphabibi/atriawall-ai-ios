import SwiftUI

@main
struct AtriaWallAIApp: App {
    @StateObject private var library = ProjectLibrary()
    @StateObject private var subscriptions = SubscriptionManager()

    var body: some Scene {
        WindowGroup {
            RootShellView()
                .environmentObject(library)
                .environmentObject(subscriptions)
                .task {
                    await subscriptions.configure()
                }
        }
    }
}
