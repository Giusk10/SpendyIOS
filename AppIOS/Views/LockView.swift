import SwiftUI

struct LockView: View {
    @State private var pin: String = ""
    @State private var showError: Bool = false
    @State private var animateContent = false
    @ObservedObject var authManager = AuthManager.shared

    let columns: [GridItem] = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
    ]

    var body: some View {
        ZStack {
            // Deep auth-flavored animated background
            AnimatedGradientBackground(
                orbs: [
                    GradientOrb(
                        color: Color.spendyPrimary.opacity(0.30),
                        size: 360,
                        blurRadius: 100,
                        initialOffset: CGSize(width: -140, height: -320),
                        amplitude: CGSize(width: 60, height: 55)
                    ),
                    GradientOrb(
                        color: Color.spendyAccent.opacity(0.24),
                        size: 290,
                        blurRadius: 85,
                        initialOffset: CGSize(width: 160, height: 360),
                        amplitude: CGSize(width: -50, height: -85)
                    ),
                    GradientOrb(
                        color: Color.spendyCyan.opacity(0.10),
                        size: 190,
                        blurRadius: 65,
                        initialOffset: CGSize(width: 120, height: -170),
                        amplitude: CGSize(width: -65, height: 48)
                    )
                ],
                baseColor: Color.spendyBackground,
                animationDuration: 14
            )

            VStack(spacing: 44) {
                Spacer()

                // MARK: - Header
                VStack(spacing: 18) {
                    LockScreenIcon()
                        .scaleEffect(animateContent ? 1 : 0.75)
                        .opacity(animateContent ? 1 : 0)
                        .animation(.spring(response: 0.5, dampingFraction: 0.68).delay(0.05), value: animateContent)

                    VStack(spacing: 6) {
                        Text("Inserisci codice")
                            .font(.system(size: 22, weight: .semibold, design: .rounded))
                            .foregroundColor(.spendyText)

                        Text("Inserisci il tuo PIN per continuare")
                            .font(.caption)
                            .foregroundColor(.spendyTertiaryText)
                    }
                    .opacity(animateContent ? 1 : 0)
                    .offset(y: animateContent ? 0 : 12)
                    .animation(.easeOut(duration: 0.4).delay(0.12), value: animateContent)
                }

                // MARK: - PIN Dots + Keypad
                Group {
                    HStack(spacing: 18) {
                        ForEach(0..<6) { index in
                            PinDot(isFilled: index < pin.count, showError: showError)
                        }
                    }
                    .shake($showError)
                    .padding(.bottom, 8)

                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(1...9, id: \.self) { number in
                            LockKeypadButton(text: "\(number)") {
                                addDigit("\(number)")
                            }
                        }

                        // Face ID / biometric slot
                        Group {
                            if authManager.isBiometricAuthenticationInProgress {
                                Color.clear.frame(width: 72, height: 72)
                            } else {
                                Button(action: {
                                    authManager.unlockWithBiometrics()
                                }) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.spendyPrimary.opacity(0.10))
                                            .frame(width: 72, height: 72)
                                            .shadow(
                                                color: Color.spendyPrimary.opacity(0.20),
                                                radius: 10,
                                                x: 0,
                                                y: 4
                                            )
                                            .overlay(
                                                Circle()
                                                    .stroke(Color.spendyGradientBorder, lineWidth: 1)
                                            )

                                        Image(systemName: "faceid")
                                            .font(.system(size: 26, weight: .medium))
                                            .foregroundStyle(Color.spendyGradient)
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        LockKeypadButton(text: "0") {
                            addDigit("0")
                        }

                        Button(action: deleteDigit) {
                            ZStack {
                                Circle()
                                    .fill(Color.clear)
                                    .frame(width: 72, height: 72)

                                Image(systemName: "delete.left")
                                    .font(.system(size: 20, weight: .medium))
                                    .foregroundColor(.spendySecondaryText)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 36)
                }
                .opacity(animateContent ? (authManager.isBiometricAuthenticationInProgress ? 0 : 1) : 0)
                .animation(
                    .easeInOut(duration: 0.3),
                    value: authManager.isBiometricAuthenticationInProgress
                )
                .animation(.easeOut(duration: 0.4).delay(0.18), value: animateContent)

                Spacer()
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                animateContent = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                authManager.unlockWithBiometrics()
            }
        }
    }

    private func addDigit(_ digit: String) {
        if pin.count < 6 {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                pin.append(digit)
            }
            if pin.count == 6 {
                verifyPin()
            }
        }
    }

    private func deleteDigit() {
        if !pin.isEmpty {
            let _ = withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                pin.removeLast()
            }
            showError = false
        }
    }

    private func verifyPin() {
        if authManager.unlock(with: pin) {
            pin = ""
        } else {
            showError = true
            pin = ""
        }
    }
}

// MARK: - Lock Screen Icon

/// Animated lock icon with a glowing pulse ring for the lock screen.
private struct LockScreenIcon: View {

    @State private var glowScale: CGFloat = 1.0
    @State private var glowOpacity: Double = 0.5

    var body: some View {
        ZStack {
            // Outer glow pulse
            Circle()
                .fill(Color.spendyPrimary.opacity(0.12))
                .frame(width: 130, height: 130)
                .scaleEffect(glowScale)
                .opacity(glowOpacity)
                .blur(radius: 4)

            // Mid ring stroke
            Circle()
                .stroke(Color.spendyPrimary.opacity(0.15), lineWidth: 2)
                .frame(width: 114, height: 114)
                .scaleEffect(glowScale)
                .opacity(glowOpacity)

            // Main background
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.spendyPrimary.opacity(0.18),
                            Color.spendyAccent.opacity(0.12)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 96, height: 96)

            // Gradient border
            Circle()
                .stroke(Color.spendyGradientBorder, lineWidth: 1.5)
                .frame(width: 96, height: 96)

            // Lock icon
            Image(systemName: "lock.fill")
                .font(.system(size: 34, weight: .medium))
                .foregroundStyle(Color.spendyGradient)
        }
        .onAppear {
            withAnimation(
                .easeInOut(duration: 2.0)
                .repeatForever(autoreverses: true)
            ) {
                glowScale = 1.14
                glowOpacity = 0.0
            }
        }
    }
}

// MARK: - Lock Keypad Button

/// Styled digit keypad button with surface fill, shadow, and spring press animation.
private struct LockKeypadButton: View {

    let text: String
    let action: () -> Void
    @State private var isPressed: Bool = false

    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.18, dampingFraction: 0.6)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.14) {
                withAnimation(.spring(response: 0.2, dampingFraction: 0.65)) {
                    isPressed = false
                }
            }
            action()
        }) {
            ZStack {
                Circle()
                    .fill(
                        isPressed
                            ? Color.spendyPrimary.opacity(0.15)
                            : Color.spendySurface
                    )
                    .frame(width: 72, height: 72)
                    .shadow(
                        color: Color.spendyShadowCard,
                        radius: isPressed ? 2 : 6,
                        x: 0,
                        y: isPressed ? 1 : 3
                    )
                    .overlay(
                        Circle()
                            .stroke(Color.spendyBorderSubtle, lineWidth: 0.5)
                    )

                Text(text)
                    .font(.system(size: 28, weight: .regular, design: .rounded))
                    .foregroundColor(.spendyText)
            }
            .scaleEffect(isPressed ? 0.93 : 1.0)
            .animation(.spring(response: 0.18, dampingFraction: 0.6), value: isPressed)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - PinDot

/// A single PIN entry indicator dot with a fill animation and pulse effect.
struct PinDot: View {
    let isFilled: Bool
    let showError: Bool

    @State private var pulseScale: CGFloat = 1.0

    var body: some View {
        ZStack {
            // Pulse ring (only when filled, no error)
            if isFilled && !showError {
                Circle()
                    .stroke(Color.spendyPrimary.opacity(0.25), lineWidth: 1.5)
                    .frame(width: 22, height: 22)
                    .scaleEffect(pulseScale)
                    .opacity(isFilled ? 0 : 0.6)
                    .animation(
                        .easeOut(duration: 0.45),
                        value: isFilled
                    )
            }

            // Main dot
            Circle()
                .fill(
                    isFilled
                        ? (showError ? Color.spendyRed : Color.spendyPrimary)
                        : Color.clear
                )
                .frame(width: 14, height: 14)
                .overlay(
                    Circle()
                        .stroke(
                            showError
                                ? Color.spendyRed
                                : (isFilled ? Color.clear : Color.spendyPrimary.opacity(0.35)),
                            lineWidth: 1.8
                        )
                )
                .scaleEffect(isFilled ? 1.12 : 1.0)
                .animation(.spring(response: 0.22, dampingFraction: 0.5), value: isFilled)
                .shadow(
                    color: isFilled && !showError
                        ? Color.spendyPrimary.opacity(0.35)
                        : .clear,
                    radius: 4,
                    x: 0,
                    y: 2
                )
        }
        .frame(width: 22, height: 22)
        .onChange(of: isFilled) { _, filled in
            if filled {
                pulseScale = 1.0
                withAnimation(.easeOut(duration: 0.45)) {
                    pulseScale = 1.7
                }
            } else {
                pulseScale = 1.0
            }
        }
    }
}
