import SwiftUI

struct NativeKeypadButton: View {
    let text: String
    var circularDiameter: CGFloat? = 76
    let action: () -> Void

    var body: some View {
        if let circularDiameter {
            Button(action: action) {
                Text(text)
                    .font(.system(size: 34, weight: .regular))
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
    var circularDiameter: CGFloat? = 76
    var biometricAction: (() -> Void)? = nil
    let onDigit: (String) -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(spacing: 36) {
            HStack(spacing: 18) {
                ForEach(0..<6) { index in
                    Circle()
                        .fill(index < count ? Color.spendyPrimary : Color.spendySurface)
                        .overlay(
                            Circle()
                                .strokeBorder(index < count ? Color.clear : Color.spendyBorderMedium.opacity(0.35), lineWidth: 1)
                        )
                        .frame(width: 14, height: 14)
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("PIN")
            .accessibilityValue("\(count) di 6 cifre inserite")
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: count)

            if error {
                Text("PIN non corretto. Riprova.")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.spendyRed)
                    .transition(.opacity)
            }

            if #available(iOS 26, *), circularDiameter != nil {
                GlassEffectContainer(spacing: 8) { keypad }
            } else {
                keypad
            }
        }
        .frame(maxWidth: 320)
    }

    private var keypad: some View {
        let diameter = circularDiameter ?? 76
        return LazyVGrid(
            columns: [
                GridItem(.fixed(diameter), spacing: 24),
                GridItem(.fixed(diameter), spacing: 24),
                GridItem(.fixed(diameter), spacing: 24)
            ],
            spacing: 20
        ) {
            ForEach(1...9, id: \.self) { number in
                NativeKeypadButton(text: String(number), circularDiameter: diameter) {
                    onDigit(String(number))
                }
            }

            if let biometricAction {
                Button(action: biometricAction) {
                    Image(systemName: "faceid")
                        .font(.system(size: 30, weight: .regular))
                        .foregroundStyle(Color.spendyText)
                        .frame(width: diameter, height: diameter)
                        .contentShape(Rectangle())
                }
                .buttonStyle(KeypadActionPressStyle())
                .accessibilityLabel("Sblocca con biometria")
            } else {
                Color.clear
                    .frame(width: diameter, height: diameter)
                    .accessibilityHidden(true)
            }

            NativeKeypadButton(text: "0", circularDiameter: diameter) {
                onDigit("0")
            }

            Button(action: onDelete) {
                Image(systemName: "delete.backward")
                    .font(.system(size: 26, weight: .regular))
                    .foregroundStyle(Color.spendyText)
                    .frame(width: diameter, height: diameter)
                    .contentShape(Rectangle())
            }
            .buttonStyle(KeypadActionPressStyle())
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
                .overlay(Circle().strokeBorder(Color.spendyBorderMedium.opacity(0.25), lineWidth: 0.5))
        }
    }
}

private struct PinKeyPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .overlay {
                Circle().fill(Color.primary.opacity(configuration.isPressed ? 0.15 : 0))
            }
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

private struct KeypadActionPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.45 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.94 : 1.0)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

struct PinHeader: View {
    let title: String
    var subtitle: String? = nil
    var showsProfileAvatar = false
    var user: User? = nil
    var avatarSize: CGFloat = 76

    var body: some View {
        VStack(spacing: 14) {
            if showsProfileAvatar {
                ProfileAvatar(user: user, size: avatarSize, usesGlass: true)
            } else {
                Image(systemName: "lock.shield")
                    .font(.largeTitle).foregroundStyle(Color.spendyPrimary)
                    .accessibilityHidden(true)
            }
            Text(title)
                .font(.title2.weight(.semibold))
                .foregroundStyle(Color.spendyText)
                .accessibilityAddTraits(.isHeader)
            if let subtitle, !subtitle.isEmpty {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(Color.spendySecondaryText)
            }
        }
        .multilineTextAlignment(.center)
    }
}
