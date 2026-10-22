import SwiftUI

enum SpendyButtonVariant {
    case primary, secondary, destructive, ghost
}

struct SpendyButton: View {
    let title: String
    var variant: SpendyButtonVariant
    var isLoading: Bool
    var isDisabled: Bool
    var leadingIcon: String?
    let action: () -> Void

    init(_ title: String, variant: SpendyButtonVariant = .primary,
         isLoading: Bool = false, isDisabled: Bool = false,
         leadingIcon: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.variant = variant
        self.isLoading = isLoading
        self.isDisabled = isDisabled
        self.leadingIcon = leadingIcon
        self.action = action
    }

    var body: some View {
        Button(role: variant == .destructive ? .destructive : nil, action: action) {
            HStack(spacing: 10) {
                if isLoading {
                    ProgressView().tint(foreground)
                } else if let leadingIcon {
                    Image(systemName: leadingIcon).accessibilityHidden(true)
                }
                Text(title).multilineTextAlignment(.center)
            }
            .font(.headline)
            .frame(maxWidth: .infinity, minHeight: 24)
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
            .foregroundStyle(foreground)
            .background(background, in: RoundedRectangle(cornerRadius: SpendyLayout.cornerRadius))
            .contentShape(RoundedRectangle(cornerRadius: SpendyLayout.cornerRadius))
            .opacity(isDisabled ? 0.5 : 1)
        }
        .buttonStyle(.plain)
        .disabled(isDisabled || isLoading)
        .accessibilityValue(isLoading ? "Operazione in corso" : "")
    }

    private var foreground: Color {
        switch variant {
        case .primary: .white
        case .destructive: .spendyRed
        case .secondary, .ghost: .spendyPrimary
        }
    }

    private var background: Color {
        switch variant {
        case .primary: .spendyPrimaryDark
        case .secondary: .spendyPrimary.opacity(0.10)
        case .destructive: .spendyRedLight
        case .ghost: .clear
        }
    }
}
