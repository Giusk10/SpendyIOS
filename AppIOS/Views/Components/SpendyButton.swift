import SwiftUI
import UIKit

// MARK: - Button Variant

/// Defines the visual and semantic variant of a SpendyButton.
enum SpendyButtonVariant {
    /// Gradient-filled primary action button (indigo to violet).
    case primary
    /// Outlined style with transparent fill and gradient stroke.
    case secondary
    /// Red-tinted destructive action button.
    case destructive
    /// Ghost/text-only style with no background.
    case ghost
}

// MARK: - SpendyButton

/// A reusable button component with multiple style variants, haptic feedback,
/// press-scale animation, and an optional loading state with spinner.
///
/// Usage:
/// ```swift
/// SpendyButton("Save") {
///     save()
/// }
///
/// SpendyButton("Delete", variant: .destructive, isLoading: isDeleting) {
///     delete()
/// }
///
/// SpendyButton("Cancel", variant: .secondary) {
///     dismiss()
/// }
/// ```
struct SpendyButton: View {

    let title: String
    let variant: SpendyButtonVariant
    let isLoading: Bool
    let isDisabled: Bool
    let leadingIcon: String?
    let action: () -> Void

    @State private var isPressed: Bool = false

    init(
        _ title: String,
        variant: SpendyButtonVariant = .primary,
        isLoading: Bool = false,
        isDisabled: Bool = false,
        leadingIcon: String? = nil,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.variant = variant
        self.isLoading = isLoading
        self.isDisabled = isDisabled
        self.leadingIcon = leadingIcon
        self.action = action
    }

    var body: some View {
        Button(action: handleTap) {
            ZStack {
                buttonBackground
                buttonContent
            }
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(buttonBorder)
            .shadow(color: shadowColor, radius: shadowRadius, x: 0, y: shadowY)
            .scaleEffect(isPressed ? 0.97 : 1.0)
            .opacity(effectiveOpacity)
            .animation(.spring(response: 0.25, dampingFraction: 0.65), value: isPressed)
        }
        .buttonStyle(.plain)
        .disabled(isDisabled || isLoading)
    }

    // MARK: - Sub-views

    @ViewBuilder
    private var buttonBackground: some View {
        switch variant {
        case .primary:
            Color.spendyGradientDeep
        case .secondary:
            Color.spendySurface
        case .destructive:
            Color.spendyRed
        case .ghost:
            Color.clear
        }
    }

    @ViewBuilder
    private var buttonContent: some View {
        if isLoading {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: spinnerColor))
                .scaleEffect(1.1)
        } else {
            HStack(spacing: 8) {
                if let icon = leadingIcon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(contentColor)
                }
                Text(title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(contentColor)
            }
        }
    }

    @ViewBuilder
    private var buttonBorder: some View {
        switch variant {
        case .secondary:
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.spendyGradientBorder, lineWidth: 1.5)
        default:
            EmptyView()
        }
    }

    // MARK: - Computed Style Properties

    private var contentColor: AnyShapeStyle {
        switch variant {
        case .primary:
            return AnyShapeStyle(.white)
        case .secondary:
            return AnyShapeStyle(Color.spendyGradient)
        case .destructive:
            return AnyShapeStyle(.white)
        case .ghost:
            return AnyShapeStyle(Color.spendyGradient)
        }
    }

    private var spinnerColor: Color {
        switch variant {
        case .primary, .destructive: return .white
        case .secondary, .ghost: return .spendyPrimary
        }
    }

    private var shadowColor: Color {
        switch variant {
        case .primary: return Color.spendyPrimary.opacity(0.35)
        case .secondary: return Color.spendyShadowNear
        case .destructive: return Color.spendyRed.opacity(0.35)
        case .ghost: return .clear
        }
    }

    private var shadowRadius: CGFloat {
        switch variant {
        case .primary, .destructive: return isPressed ? 4 : 12
        case .secondary: return 4
        case .ghost: return 0
        }
    }

    private var shadowY: CGFloat {
        switch variant {
        case .primary, .destructive: return isPressed ? 2 : 6
        case .secondary: return 2
        case .ghost: return 0
        }
    }

    private var effectiveOpacity: Double {
        isDisabled ? 0.45 : 1.0
    }

    // MARK: - Actions

    private func handleTap() {
        guard !isDisabled && !isLoading else { return }
        triggerHaptic()
        withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
            isPressed = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                isPressed = false
            }
        }
        action()
    }

    private func triggerHaptic() {
        let style: UIImpactFeedbackGenerator.FeedbackStyle
        switch variant {
        case .primary: style = .medium
        case .secondary: style = .light
        case .destructive: style = .rigid
        case .ghost: style = .soft
        }
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
}

// MARK: - Preview

#Preview("SpendyButton Variants") {
    VStack(spacing: 20) {
        SpendyButton("Accedi", leadingIcon: "arrow.right.circle.fill") {}

        SpendyButton("Annulla", variant: .secondary) {}

        SpendyButton("Elimina", variant: .destructive, leadingIcon: "trash.fill") {}

        SpendyButton("Vedi dettagli", variant: .ghost) {}

        SpendyButton("Caricamento...", isLoading: true) {}

        SpendyButton("Non disponibile", isDisabled: true) {}
    }
    .padding(24)
    .background(Color.spendyBackground)
}
