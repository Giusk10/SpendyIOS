import SwiftUI

struct NativeKeypadButton: View {
    let text: String
    var circularDiameter: CGFloat? = nil
    let action: () -> Void

    var body: some View {
        if let circularDiameter {
            Button(action: action) {
                Text(text)
                    .font(.largeTitle.weight(.regular))
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .foregroundStyle(Color.spendyText)
                    .frame(width: circularDiameter, height: circularDiameter)
                    .modifier(PinCircularSurface())
                    .contentShape(Circle())
            }
            .buttonStyle(PinKeyPressStyle())
        } else {
            legacyButton
        }
    }

    private var legacyButton: some View {
        Button(action: action) {
            Text(text).font(.title.weight(.medium))
                .frame(maxWidth: .infinity, minHeight: 64)
                .foregroundStyle(Color.spendyText)
                .background(Color.spendySurface, in: RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }
}

struct PinEntryPad: View {
    let count: Int
    let error: Bool
    var circularDiameter: CGFloat? = nil
    var biometricAction: (() -> Void)? = nil
    let onDigit: (String) -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            HStack(spacing: 18) {
                ForEach(0..<6) { index in
                    Circle()
                        .fill(index < count ? Color.spendyPrimary : Color.spendyBackgroundDeep)
                        .frame(width: 14, height: 14)
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("PIN")
            .accessibilityValue("\(count) di 6 cifre inserite")
            if error {
                Text("PIN non corretto. Riprova.")
                    .font(.subheadline).foregroundStyle(Color.spendyRed)
            }
            if #available(iOS 26, *), circularDiameter != nil {
                GlassEffectContainer(spacing: 8) { keypad }
            } else {
                keypad
            }
        }
        .frame(maxWidth: 340)
    }

    private var keypad: some View {
        LazyVGrid(columns: Array(repeating: GridItem(
            .flexible(),
            spacing: circularDiameter == nil ? nil : 20), count: 3),
                  spacing: circularDiameter == nil ? 12 : 20) {
            ForEach(1...9, id: \.self) { number in
                NativeKeypadButton(text: String(number), circularDiameter: circularDiameter) { onDigit(String(number)) }
            }
            if let biometricAction {
                Button(action: biometricAction) {
                    Image(systemName: "faceid")
                        .font(.title2)
                        .frame(maxWidth: .infinity, minHeight: circularDiameter ?? 64)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .foregroundStyle(Color.spendyPrimary)
                .accessibilityLabel("Sblocca con biometria")
            } else {
                Color.clear.frame(height: circularDiameter ?? 64).accessibilityHidden(true)
            }
            NativeKeypadButton(text: "0", circularDiameter: circularDiameter) { onDigit("0") }
            Button(action: onDelete) {
                Image(systemName: "delete.left")
                    .font(.title2)
                    .frame(maxWidth: .infinity, minHeight: circularDiameter ?? 64)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(Color.spendyPrimary)
            .accessibilityLabel("Cancella ultima cifra")
        }
    }
}

/// A single native surface with an opaque accessibility fallback.
struct PinCircularSurface: ViewModifier {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorSchemeContrast) private var contrast

    func body(content: Content) -> some View {
        if #available(iOS 26, *), !reduceTransparency, contrast != .increased {
            content.glassEffect(.regular.tint(Color.spendySurface.opacity(0.85)), in: Circle())
        } else {
            content
                .background(Color.spendySurface, in: Circle())
                .overlay(Circle().strokeBorder(Color.spendyBorderMedium, lineWidth: 0.5))
        }
    }
}

private struct PinKeyPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .overlay {
                Circle().fill(Color.primary.opacity(configuration.isPressed ? 0.10 : 0))
            }
    }
}

struct PinHeader: View {
    let title: String
    let subtitle: String
    var showsProfileAvatar = false
    var user: User? = nil

    var body: some View {
        VStack(spacing: 12) {
            if showsProfileAvatar {
                ProfileAvatar(user: user, usesGlass: true)
            } else {
                Image(systemName: "lock.shield")
                    .font(.largeTitle).foregroundStyle(Color.spendyPrimary)
                    .accessibilityHidden(true)
            }
            Text(title).font(.title2.bold()).accessibilityAddTraits(.isHeader)
            Text(subtitle).font(.subheadline).foregroundStyle(Color.spendySecondaryText)
        }
        .multilineTextAlignment(.center)
    }
}
