import SwiftUI

struct PinSetupView: View {
    @State private var pin: String = ""
    @State private var confirmPin: String = ""
    @State private var isConfirming: Bool = false
    @State private var showError: Bool = false
    @State private var message: String = "Crea un PIN a 6 cifre"
    
    @ObservedObject var authManager = AuthManager.shared
    
    let columns: [GridItem] = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        ZStack {
            // Background - Consistent with LockView
             LinearGradient(colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.4)], startPoint: .topLeading, endPoint: .bottomTrailing)
                 .ignoresSafeArea()
                 .overlay(.ultraThinMaterial)
            
             Color.black.opacity(0.4).ignoresSafeArea()
            
            VStack(spacing: 50) {
                Spacer()
                
                VStack(spacing: 20) {
                    Text("Imposta sicurezza")
                        .font(.system(size: 34, weight: .bold)) // Apple Title 1
                        .foregroundColor(.white)
                        .shadow(radius: 5)
                    
                    Text(message)
                        .font(.body)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                // PIN Dots
                HStack(spacing: 25) {
                    ForEach(0..<6) { index in
                        let char = isConfirming ? confirmPin : pin
                        Circle()
                            .fill(index < char.count ? Color.white : Color.white.opacity(0.2))
                            .frame(width: 14, height: 14)
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.5), lineWidth: 1)
                            )
                            .shadow(color: index < char.count ? .white.opacity(0.5) : .clear, radius: 8, x: 0, y: 0)
                    }
                }
                .shake($showError)
                .padding(.bottom, 30)
                
                // Numpad
                LazyVGrid(columns: columns, spacing: 25) {
                    ForEach(1...9, id: \.self) { number in
                        LiquidKeypadButton(number: "\(number)") {
                            addDigit("\(number)")
                        }
                    }
                    
                    Color.clear.frame(width: 75, height: 75)
                    
                    LiquidKeypadButton(number: "0") {
                        addDigit("0")
                    }
                    
                    Button(action: {
                        deleteDigit()
                    }) {
                        Image(systemName: "delete.left.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white.opacity(0.8))
                            .frame(width: 75, height: 75)
                    }
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 20)
                
                Spacer()
            }
        }
    }
    
    private func addDigit(_ digit: String) {
        if !isConfirming {
            if pin.count < 6 {
                pin.append(digit)
                if pin.count == 6 {
                    startConfirmation()
                }
            }
        } else {
            if confirmPin.count < 6 {
                confirmPin.append(digit)
                if confirmPin.count == 6 {
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
                message = "Crea un PIN a 6 cifre"
                pin = ""
            }
        }
        showError = false
    }
    
    private func startConfirmation() {
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
                message = "Crea un PIN a 6 cifre"
                pin = ""
                confirmPin = ""
                showError = false
            }
        }
    }
}
