import SwiftUI
import UIKit

struct CustomTabBar: View {
    @Binding var selectedTab: TabBarItem

    var body: some View {
        HStack(spacing: 0) {
            ForEach(TabBarItem.allCases, id: \.self) { tab in
                Spacer()

                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = tab
                    }
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                }) {
                    VStack(spacing: 4) {
                        if tab == .upload {
                            Image(systemName: tab.iconName)
                                .font(.system(size: 32, weight: .bold))  // Larger for upload
                                .foregroundStyle(
                                    selectedTab == tab
                                        ? AnyShapeStyle(Color.spendyGradient)
                                        : AnyShapeStyle(Color.spendySecondaryText)
                                )
                                .scaleEffect(selectedTab == tab ? 1.1 : 1.0)
                                .shadow(
                                    color: selectedTab == tab
                                        ? Color.spendyAccent.opacity(0.3) : Color.clear, radius: 8,
                                    x: 0, y: 4)
                        } else {
                            Image(systemName: tab.iconName)
                                .font(.system(size: 24, weight: .medium))
                                .foregroundColor(
                                    selectedTab == tab ? .spendyPrimary : .spendySecondaryText
                                )
                                .scaleEffect(selectedTab == tab ? 1.2 : 1.0)
                        }
                    }
                    .frame(width: 50, height: 50)
                }
                .buttonStyle(.plain)

                Spacer()
            }
        }
        .padding(.top, 10)
        .background(
            ZStack {
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .ignoresSafeArea()

                // Top border line for subtle separation
                VStack {
                    Divider()
                        .background(Color.black.opacity(0.1))
                    Spacer()
                }
            }
        )
        // Ensure it sits at the bottom of the screen including safe area
        .frame(height: 60)
    }
}
