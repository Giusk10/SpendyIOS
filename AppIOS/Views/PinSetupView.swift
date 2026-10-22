import SwiftUI

struct PinSetupView: View {
    @ObservedObject private var authManager = AuthManager.shared
    @State private var pin = ""
    @State private var confirmation = ""
    @State private var isConfirming = false
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                PinHeader(title: isConfirming ? "Conferma il PIN" : "Proteggi il tuo accesso",
                          subtitle: isConfirming ? "Inserisci di nuovo le sei cifre." : "Crea un PIN a sei cifre.")
                if let errorMessage { SpendyMessage(message: errorMessage) }
                PinEntryPad(count: isConfirming ? confirmation.count : pin.count,
                            error: false, onDigit: addDigit, onDelete: deleteDigit)
                if isConfirming {
                    Button("Scegli un altro PIN") { reset() }.frame(minHeight: 44)
                }
            }
            .padding(24).padding(.top, 24)
            .frame(maxWidth: .infinity)
        }
        .background(Color.spendyBackground)
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
