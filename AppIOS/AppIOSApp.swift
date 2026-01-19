import SwiftUI

@main
struct AppIOSApp: App {
    @Environment(\.scenePhase) var scenePhase
    @StateObject private var authManager = AuthManager.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.light)
                .onChange(of: scenePhase) { _, newPhase in
                    if newPhase == .background {
                        authManager.lockApp()
                    }
                }
        }
    }
}
