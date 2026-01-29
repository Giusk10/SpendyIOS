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
                    VStack(spacing: 4) {
                        Image(systemName: selectedTab == tab ? tab.iconName : tab.iconNameOutline)
                            .font(.system(size: 22, weight: .medium))
                            .foregroundColor(
                                selectedTab == tab ? .spendyPrimary : .spendyTertiaryText)

                        Text(tab.title)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(
                                selectedTab == tab ? .spendyPrimary : .spendyTertiaryText)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 4)
        .background(
            VStack(spacing: 0) {
                Rectangle()
                    .fill(Color.spendySecondaryText.opacity(0.1))
                    .frame(height: 0.5)
                Rectangle()
                    .fill(Color.white)
            }
            .ignoresSafeArea()
        )
    }
}
