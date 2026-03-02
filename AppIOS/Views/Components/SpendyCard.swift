import SwiftUI

// MARK: - Card Style

/// Defines the visual elevation level of a SpendyCard.
enum SpendyCardStyle {
    /// Flat surface with subtle multi-layer shadow. Suitable for list items and content blocks.
    case `default`
    /// Deeper multi-layer shadow for floating panels and featured sections.
    case elevated
    /// A gradient stroke border with lighter fill for highlighted/premium content.
    case gradientBordered
}

// MARK: - SpendyCard

/// A reusable card container that wraps any content with consistent surface styling.
///
/// Usage:
/// ```swift
/// SpendyCard {
///     Text("Hello")
/// }
///
/// SpendyCard(style: .elevated) {
///     SomeView()
/// }
///
/// SpendyCard(style: .gradientBordered, padding: 20) {
///     PremiumContent()
/// }
/// ```
struct SpendyCard<Content: View>: View {

    let style: SpendyCardStyle
    let padding: CGFloat
    let cornerRadius: CGFloat
    @ViewBuilder let content: Content

    init(
        style: SpendyCardStyle = .default,
        padding: CGFloat = 16,
        cornerRadius: CGFloat = 20,
        @ViewBuilder content: () -> Content
    ) {
        self.style = style
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .background(cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(borderOverlay)
            .shadow(color: Color.spendyShadowFar, radius: outerShadowRadius, x: 0, y: outerShadowY)
            .shadow(color: Color.spendyShadowNear, radius: innerShadowRadius, x: 0, y: innerShadowY)
    }

    // MARK: - Style Helpers

    @ViewBuilder
    private var cardBackground: some View {
        switch style {
        case .default, .elevated:
            Color.spendySurface
        case .gradientBordered:
            Color.spendySurfaceElevated
        }
    }

    @ViewBuilder
    private var borderOverlay: some View {
        switch style {
        case .default:
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(Color.spendyBorderSubtle, lineWidth: 0.5)
        case .elevated:
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(Color.spendyBorderSubtle, lineWidth: 0.5)
        case .gradientBordered:
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(Color.spendyGradientBorder, lineWidth: 1.5)
        }
    }

    private var outerShadowRadius: CGFloat {
        switch style {
        case .default: return 16
        case .elevated: return 28
        case .gradientBordered: return 20
        }
    }

    private var outerShadowY: CGFloat {
        switch style {
        case .default: return 6
        case .elevated: return 12
        case .gradientBordered: return 8
        }
    }

    private var innerShadowRadius: CGFloat {
        switch style {
        case .default: return 4
        case .elevated: return 8
        case .gradientBordered: return 4
        }
    }

    private var innerShadowY: CGFloat {
        switch style {
        case .default: return 2
        case .elevated: return 4
        case .gradientBordered: return 2
        }
    }
}

// MARK: - Preview

#Preview("SpendyCard Styles") {
    ScrollView {
        VStack(spacing: 24) {
            SpendyCard(style: .default) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Default Card")
                            .font(.headline)
                            .foregroundColor(.spendyText)
                        Text("Subtle multi-layer shadow")
                            .font(.caption)
                            .foregroundColor(.spendySecondaryText)
                    }
                    Spacer()
                    Image(systemName: "creditcard.fill")
                        .font(.title2)
                        .foregroundStyle(Color.spendyGradient)
                }
            }

            SpendyCard(style: .elevated) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Elevated Card")
                            .font(.headline)
                            .foregroundColor(.spendyText)
                        Text("Deeper shadow depth")
                            .font(.caption)
                            .foregroundColor(.spendySecondaryText)
                    }
                    Spacer()
                    Image(systemName: "star.fill")
                        .font(.title2)
                        .foregroundStyle(Color.spendyGradient)
                }
            }

            SpendyCard(style: .gradientBordered) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Gradient Border")
                            .font(.headline)
                            .foregroundColor(.spendyText)
                        Text("Premium highlighted card")
                            .font(.caption)
                            .foregroundColor(.spendySecondaryText)
                    }
                    Spacer()
                    Image(systemName: "sparkles")
                        .font(.title2)
                        .foregroundStyle(Color.spendyGradient)
                }
            }
        }
        .padding(20)
    }
    .background(Color.spendyBackground)
}
