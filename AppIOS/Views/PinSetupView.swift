import SwiftUI

struct PinSetupView: View {
    @State private var pin: String = ""
    @State private var confirmPin: String = ""
    @State private var isConfirming: Bool = false
    @State private var showError: Bool = false
    @State private var message: String = "Crea un PIN a 4 cifre"
    
    @ObservedObject var authManager = AuthManager.shared
    
    let columns: [GridItem] = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                VStack(spacing: 16) {
                    Text("Imposta sicurezza")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text(message)
                        .font(.body)
                        .foregroundColor(.gray)
                }
                
                HStack(spacing: 20) {
                    ForEach(0..<4) { index in
                        let char = isConfirming ? confirmPin : pin
                        Circle()
                            .fill(index < char.count ? Color.white : Color.gray.opacity(0.3))
                            .frame(width: 20, height: 20)
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: 1)
                            )
                    }
                }
                .shake($showError)
                
                Spacer()
                
                LazyVGrid(columns: columns, spacing: 30) {
                    ForEach(1...9, id: \.self) { number in
                        NumberButton(number: "\(number)") {
                            addDigit("\(number)")
                        }
                    }
                    
                    Color.clear.frame(width: 80, height: 80)
                    
                    NumberButton(number: "0") {
                        addDigit("0")
                    }
                    
                    Button(action: {
                        deleteDigit()
                    }) {
                        Image(systemName: "delete.left.fill")
                            .font(.title)
                            .foregroundColor(.white)
                            .frame(width: 80, height: 80)
                    }
                }
                .padding(.horizontal, 40)
                
                Spacer()
            }
        }
    }
    
    private func addDigit(_ digit: String) {
        if !isConfirming {
            if pin.count < 4 {
                pin.append(digit)
                if pin.count == 4 {
                    startConfirmation()
                }
            }
        } else {
            if confirmPin.count < 4 {
                confirmPin.append(digit)
                if confirmPin.count == 4 {
                    validatePin()
                }
            }
        }
    }
    
    private func deleteDigit() {
        if !isConfirming {
            if !pin.isEmpty {
                pin.removeLast()
            }
        } else {
            if !confirmPin.isEmpty {
                confirmPin.removeLast()
            } else {
                // Back to first entry
                isConfirming = false
                message = "Crea un PIN a 4 cifre"
                pin = "" // Clear first pin too? Or keep it? Usually better to restart or just allow editing.
                // To keep it simple, if they delete empty confirm, we go back to step 1 with empty pin.
            }
        }
        showError = false
    }
    
    private func startConfirmation() {
        // Short delay or immediate
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            isConfirming = true
            message = "Conferma il tuo PIN"
        }
    }
    
    private func validatePin() {
        if pin == confirmPin {
            authManager.savePin(pin)
        } else {
            showError = true
            message = "I PIN non corrispondono. Riprova."
            
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                // Reset flow
                isConfirming = false
                message = "Crea un PIN a 4 cifre"
                pin = ""
                confirmPin = ""
                showError = false
            }
        }
    }
}
