import SwiftUI

struct PinSetupView: View {
    @ObservedObject private var authManager = AuthManager.shared
    @State private var pin = ""
    @State private var confirmation = ""
    @State private var isConfirming = false
    @State private var errorMessage: String?

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 24) {
                    Spacer(minLength: 12)
                    PinHeader(title: isConfirming ? "Conferma il PIN" : "Proteggi il tuo accesso",
                              subtitle: isConfirming ? "Inserisci di nuovo le sei cifre." : "Crea un PIN a sei cifre.",
                              showsProfileAvatar: false)
                    if let errorMessage { SpendyMessage(message: errorMessage) }
                    Spacer(minLength: 8)
                    PinEntryPad(count: isConfirming ? confirmation.count : pin.count,
                                error: false,
                                circularDiameter: keyDiameter(in: geometry.size),
                                onDigit: addDigit,
                                onDelete: deleteDigit)
                    Spacer(minLength: 12)
                    if isConfirming {
                        Button("Scegli un altro PIN") { reset() }
                            .font(.subheadline)
                            .frame(minHeight: 44)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity)
                .frame(minHeight: geometry.size.height)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .background(Color.spendyBackground)
    }

    private func keyDiameter(in size: CGSize) -> CGFloat {
        min(80, max(68, (size.width - 120) / 3))
    }

    private func addDigit(_ digit: String) {
        errorMessage = nil
        if isConfirming {
            guard confirmation.count < 6 else { return }
            confirmation.append(digit)
            if confirmation.count == 6 {
                if pin == confirmation {
                    authManager.savePin(pin)
                } else {
                    reset()
                    errorMessage = "I PIN non corrispondono. Scegli di nuovo il PIN."
                }
            }
        } else {
            guard pin.count < 6 else { return }
            pin.append(digit)
            if pin.count == 6 { isConfirming = true }
        }
    }

    private func deleteDigit() {
        if isConfirming {
            if confirmation.isEmpty { reset() } else { confirmation.removeLast() }
        } else if !pin.isEmpty {
            pin.removeLast()
        }
    }

    private func reset() {
        pin = ""
        confirmation = ""
        isConfirming = false
        errorMessage = nil
    }
}
