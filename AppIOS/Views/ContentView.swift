import SwiftUI

struct ContentView: View {
    @ObservedObject private var authManager = AuthManager.shared

    var body: some View {
        switch authManager.authState {
        case .unauthenticated: AuthView()
        case .authenticated: MainTabView()
        case .locked: LockView()
        case .pinSetup: PinSetupView()
        }
    }
}

struct MainTabView: View {
    @State private var transactions = DashboardViewModel()

    var body: some View {
        TabView {
            Tab("Home", systemImage: "house") { DashboardView() }
            Tab("Analisi", systemImage: "chart.bar") { AnalyticsView() }
        }
        .environment(transactions)
        .tint(.spendyPrimary)
    }
}
