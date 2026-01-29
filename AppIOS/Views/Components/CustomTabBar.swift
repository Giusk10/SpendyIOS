import SwiftUI
import UIKit

struct CustomTabBar: View {
    @Binding var selectedTab: TabBarItem

    var body: some View {
        HStack(spacing: 0) {
            ForEach(TabBarItem.allCases, id: \.self) { tab in
                Button(action: {
                    selectedTab = tab
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                }) {
                    VStack(spacing: 2) {
                        Image(systemName: selectedTab == tab ? tab.iconName : tab.iconNameOutline)
                            .font(.system(size: 40, weight: .medium))
                            .foregroundColor(
                                selectedTab == tab ? .spendyPrimary : .spendyTertiaryText)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 24)
        .background(
            Rectangle()
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: -2)
                .ignoresSafeArea()
        )
    }
}
