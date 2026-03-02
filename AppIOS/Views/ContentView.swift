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
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: authManager.authState)
    }
}

struct MainTabView: View {
    @State private var selectedTab: Int = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem {
                    Label(
                        "Home",
                        systemImage: selectedTab == 0 ? "house.fill" : "house"
                    )
                }
                .tag(0)

            AnalyticsView()
                .tabItem {
                    Label(
                        "Analytics",
                        systemImage: selectedTab == 1 ? "chart.pie.fill" : "chart.pie"
                    )
                }
                .tag(1)
        }
        .tint(.spendyPrimary)
        .onAppear {
            styleTabBar()
        }
    }

    // MARK: - Tab Bar Appearance

    private func styleTabBar() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()

        // Background: warm surface color matching the design system
        appearance.backgroundColor = UIColor(Color.spendySurface)

        // Top separator line: subtle violet-tinted border
        appearance.shadowColor = UIColor(Color.spendyBorderSubtle)

        // Unselected item: muted tertiary text
        let unselected = UITabBarItemAppearance()
        unselected.normal.iconColor = UIColor(Color.spendyTertiaryText)
        unselected.normal.titleTextAttributes = [
            .foregroundColor: UIColor(Color.spendyTertiaryText),
            .font: UIFont.systemFont(ofSize: 10, weight: .medium)
        ]

        // Selected item: brand primary (indigo)
        unselected.selected.iconColor = UIColor(Color.spendyPrimary)
        unselected.selected.titleTextAttributes = [
            .foregroundColor: UIColor(Color.spendyPrimary),
            .font: UIFont.systemFont(ofSize: 10, weight: .bold)
        ]

        appearance.stackedLayoutAppearance = unselected
        appearance.inlineLayoutAppearance = unselected
        appearance.compactInlineLayoutAppearance = unselected

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}
