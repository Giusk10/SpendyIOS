import SwiftUI
import UIKit

struct PinSetupView: View {
    @State private var pin: String = ""
    @State private var confirmPin: String = ""
    @State private var isConfirming: Bool = false
    @State private var showError: Bool = false
    @State private var message: String = "Crea un PIN a 6 cifre"
    @State private var animateContent = false

    @ObservedObject var authManager = AuthManager.shared

    let columns: [GridItem] = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
    ]

    var body: some View {
        ZStack {
            // Deeper, auth-flavored animated background
            AnimatedGradientBackground(
                orbs: [
                    GradientOrb(
                        color: Color.spendyPrimary.opacity(0.28),
                        size: 340,
                        blurRadius: 90,
                        initialOffset: CGSize(width: -130, height: -310),
                        amplitude: CGSize(width: 55, height: 50)
                    ),
                    GradientOrb(
                        color: Color.spendyAccent.opacity(0.22),
                        size: 280,
                        blurRadius: 80,
                        initialOffset: CGSize(width: 150, height: 340),
                        amplitude: CGSize(width: -45, height: -80)
                    ),
                    GradientOrb(
                        color: Color.spendyCyan.opacity(0.10),
                        size: 180,
                        blurRadius: 60,
                        initialOffset: CGSize(width: 110, height: -160),
                        amplitude: CGSize(width: -60, height: 45)
                    )
                ],
                baseColor: Color.spendyBackground,
                animationDuration: 14
            )

            VStack(spacing: 44) {
                Spacer()

                // MARK: - Header
                VStack(spacing: 18) {
                    AnimatedLockIcon(isConfirming: isConfirming)
                        .scaleEffect(animateContent ? 1 : 0.75)
                        .opacity(animateContent ? 1 : 0)
                        .animation(.spring(response: 0.5, dampingFraction: 0.68).delay(0.05), value: animateContent)

                    VStack(spacing: 6) {
                        Text(message)
                            .font(.system(size: 22, weight: .semibold, design: .rounded))
                            .foregroundColor(.spendyText)
                            .multilineTextAlignment(.center)
                            .contentTransition(.opacity)
                            .animation(.easeInOut(duration: 0.22), value: message)

                        Text("Il PIN protegge il tuo accesso all'app")
                            .font(.caption)
                            .foregroundColor(.spendyTertiaryText)
                            .opacity(isConfirming ? 0 : 1)
                            .animation(.easeInOut(duration: 0.2), value: isConfirming)
                    }
                    .opacity(animateContent ? 1 : 0)
                    .offset(y: animateContent ? 0 : 12)
                    .animation(.easeOut(duration: 0.4).delay(0.12), value: animateContent)
                }

                // MARK: - PIN Dots
                HStack(spacing: 18) {
                    ForEach(0..<6) { index in
                        let currentPin = isConfirming ? confirmPin : pin
                        PinDot(isFilled: index < currentPin.count, showError: showError)
                    }
                }
                .shake($showError)
                .padding(.bottom, 8)
                .opacity(animateContent ? 1 : 0)
                .animation(.easeOut(duration: 0.4).delay(0.18), value: animateContent)

                // MARK: - Keypad
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(1...9, id: \.self) { number in
                        PinKeypadButton(text: "\(number)") {
                            addDigit("\(number)")
                        }
                    }

                    Color.clear.frame(width: 72, height: 72)

                    PinKeypadButton(text: "0") {
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
                .opacity(animateContent ? 1 : 0)
                .animation(.easeOut(duration: 0.4).delay(0.22), value: animateContent)

                Spacer()
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                animateContent = true
            }
        }
    }

    private func addDigit(_ digit: String) {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()

        if !isConfirming {
            if pin.count < 6 {
                withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                    pin.append(digit)
                }
                if pin.count == 6 {
                    startConfirmation()
                }
            }
        } else {
            if confirmPin.count < 6 {
                withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                    confirmPin.append(digit)
                }
                if confirmPin.count == 6 {
                    validatePin()
                }
            }
        }
    }

    private func deleteDigit() {
        if !isConfirming {
            if !pin.isEmpty {
                let _ = withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                    pin.removeLast()
                }
            }
        } else {
            if !confirmPin.isEmpty {
                let _ = withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                    confirmPin.removeLast()
                }
            } else {
                isConfirming = false
                message = "Crea un PIN a 6 cifre"
                pin = ""
            }
        }
        showError = false
    }

    private func startConfirmation() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeInOut) {
                isConfirming = true
                message = "Conferma il tuo PIN"
            }
        }
    }

    private func validatePin() {
        if pin == confirmPin {
            authManager.savePin(pin)
        } else {
            showError = true
            message = "I PIN non corrispondono"

            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation(.easeInOut) {
                    isConfirming = false
                    message = "Crea un PIN a 6 cifre"
                    pin = ""
                    confirmPin = ""
                    showError = false
                }
            }
        }
    }
}

// MARK: - Animated Lock Icon

/// Lock icon with a pulsing gradient ring that swaps the symbol when confirming.
private struct AnimatedLockIcon: View {

    let isConfirming: Bool
    @State private var pulseScale: CGFloat = 1.0
    @State private var pulseOpacity: Double = 0.6

    var body: some View {
        ZStack {
            // Outer pulse ring
            Circle()
                .stroke(Color.spendyPrimary.opacity(0.18), lineWidth: 2)
                .frame(width: 114, height: 114)
                .scaleEffect(pulseScale)
                .opacity(pulseOpacity)

            // Background orb
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

            // Gradient border ring
            Circle()
                .stroke(Color.spendyGradientBorder, lineWidth: 1.5)
                .frame(width: 96, height: 96)

            // Icon
            Image(systemName: isConfirming ? "lock.rotation" : "lock.fill")
                .font(.system(size: 34, weight: .medium))
                .foregroundStyle(Color.spendyGradient)
                .contentTransition(.symbolEffect(.replace))
                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isConfirming)
        }
        .onAppear {
            withAnimation(
                .easeInOut(duration: 1.8)
                .repeatForever(autoreverses: true)
            ) {
                pulseScale = 1.12
                pulseOpacity = 0.0
            }
        }
    }
}

// MARK: - PIN Keypad Button

/// Styled digit keypad button with gradient fill and spring press animation.
private struct PinKeypadButton: View {

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
                            .stroke(
                                Color.spendyBorderSubtle,
                                lineWidth: 0.5
                            )
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
