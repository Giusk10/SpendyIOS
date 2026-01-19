import SwiftUI

struct ContentView: View {
    @ObservedObject var authManager = AuthManager.shared
    
    var body: some View {
        Group {
            switch authManager.authState {
            case .unauthenticated:
                AuthView()
            case .authenticated:
                MainTabView()
            case .locked:
                LockView()
            case .pinSetup:
                PinSetupView()
            }
        }
        .animation(.default, value: authManager.authState)
    }
}

struct MainTabView: View {
    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("Expenses", systemImage: "list.bullet")
                }
            
            NavigationView {
                 UploadView()
            }
            .tabItem {
                Label("Upload", systemImage: "arrow.up.doc")
            }
            
            AnalyticsView()
                .tabItem {
                    Label("Analytics", systemImage: "chart.bar")
                }
        }
    }
}
