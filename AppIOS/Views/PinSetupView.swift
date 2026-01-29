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
            Color.white.ignoresSafeArea()

            Circle()
                .fill(Color.spendyPrimary.opacity(0.06))
                .frame(width: 400)
                .blur(radius: 80)
                .offset(x: -100, y: -300)

            Circle()
                .fill(Color.spendyAccent.opacity(0.05))
                .frame(width: 300)
                .blur(radius: 60)
                .offset(x: 150, y: 400)

            VStack(spacing: 40) {
                Spacer()

                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.spendyPrimary.opacity(0.15),
                                        Color.spendyAccent.opacity(0.1),
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 90, height: 90)

                        Image(systemName: isConfirming ? "lock.rotation" : "lock.fill")
                            .font(.system(size: 36, weight: .medium))
                            .foregroundStyle(Color.spendyGradient)
                    }
                    .scaleEffect(animateContent ? 1 : 0.8)
                    .opacity(animateContent ? 1 : 0)

                    Text(message)
                        .font(.system(size: 24, weight: .semibold, design: .rounded))
                        .foregroundColor(.spendyText)
                        .multilineTextAlignment(.center)
                        .opacity(animateContent ? 1 : 0)
                }

                HStack(spacing: 20) {
                    ForEach(0..<6) { index in
                        let currentPin = isConfirming ? confirmPin : pin
                        PinDot(isFilled: index < currentPin.count, showError: showError)
                    }
                }
                .shake($showError)
                .padding(.bottom, 20)

                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(1...9, id: \.self) { number in
                        NativeKeypadButton(text: "\(number)") {
                            addDigit("\(number)")
                        }
                    }

                    Color.clear.frame(width: 75, height: 75)

                    NativeKeypadButton(text: "0") {
                        addDigit("0")
                    }

                    Button(action: {
                        deleteDigit()
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color.clear)
                                .frame(width: 75, height: 75)

                            Image(systemName: "delete.left")
                                .font(.system(size: 22, weight: .medium))
                                .foregroundColor(.spendySecondaryText)
                        }
                    }
                }
                .padding(.horizontal, 40)

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
