import SwiftUI

struct LockView: View {
    @State private var pin: String = ""
    @State private var showError: Bool = false
    @ObservedObject var authManager = AuthManager.shared
    
    // Number pad layout
    let columns: [GridItem] = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        ZStack {
            // Background - Deep gradient or blurred image to enhance glass effect
            LinearGradient(colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.4)], startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
                .overlay(.ultraThinMaterial) // Frost effect base
            
            // Or just keep the app content blurred behind?
            // User asked for "Liquid Glass", usually implies seeing what's behind or having a rich background.
            // For a lock screen, usually we want a solid or heavily blurred background.
            // Let's us a nice dark gradient background to make the "Glass" buttons pop.
             Color.black.opacity(0.4).ignoresSafeArea()
            
            VStack(spacing: 50) {
                Spacer()
                
                VStack(spacing: 20) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.white.opacity(0.9))
                        .shadow(radius: 5)
                    
                    Text("Inserisci codice")
                        .font(.system(size: 22, weight: .regular))
                        .foregroundColor(.white)
                        .shadow(radius: 5)
                }
                
                // PIN Dots - Liquid Style
                HStack(spacing: 25) {
                    ForEach(0..<6) { index in
                        Circle()
                            .fill(index < pin.count ? Color.white : Color.white.opacity(0.2))
                            .frame(width: 14, height: 14)
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.5), lineWidth: 1)
                            )
                            .shadow(color: index < pin.count ? .white.opacity(0.5) : .clear, radius: 8, x: 0, y: 0)
                    }
                }
                .shake($showError)
                .padding(.bottom, 30)
                
                // Numpad - Liquid Glass Buttons
                LazyVGrid(columns: columns, spacing: 25) {
                    ForEach(1...9, id: \.self) { number in
                        LiquidKeypadButton(number: "\(number)") {
                            addDigit("\(number)")
                        }
                    }
                    
                    // FaceID / Empty
                    Group {
                        Button(action: {
                            authManager.unlockWithBiometrics()
                        }) {
                            Image(systemName: "faceid")
                                .font(.system(size: 28))
                                .foregroundColor(.white)
                                .frame(width: 75, height: 75)
                        }
                    }
                    
                    LiquidKeypadButton(number: "0") {
                        addDigit("0")
                    }
                    
                    // Delete
                    Button(action: {
                        deleteDigit()
                    }) {
                        Text("Elimina")
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(.white)
                            .frame(width: 75, height: 75)
                    }
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 20)
                
                Spacer()
            }
        }
        .onAppear {
             // Small delay to allow UI to settle before prompting FaceID
             DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                 authManager.unlockWithBiometrics()
             }
        }
    }
    
    private func addDigit(_ digit: String) {
        if pin.count < 6 {
            pin.append(digit)
            if pin.count == 6 {
                verifyPin()
            }
        }
    }
    
    private func deleteDigit() {
        if !pin.isEmpty {
            pin.removeLast()
            showError = false
        }
    }
    
    private func verifyPin() {
        if authManager.unlock(with: pin) {
            pin = ""
        } else {
            showError = true
            pin = ""
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
        }
    }
}

// Reusable Liquid Glass Button
struct LiquidKeypadButton: View {
    let number: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                // Liquid Glass Background
                Circle()
                    .fill(.ultraThinMaterial)
                    .background(
                        Circle()
                            .fill(Color.white.opacity(0.1))
                            .blur(radius: 0)
                    )
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [.white.opacity(0.6), .white.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    )
                    .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
                
                Text(number)
                    .font(.system(size: 34, weight: .regular))
                    .foregroundColor(.white)
            }
            .frame(width: 75, height: 75)
        }
    }
}

// Helper for Shake Animation
struct ShakeEffect: GeometryEffect {
    var amount: CGFloat = 10
    var shakesPerUnit = 3
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX:
            amount * sin(animatableData * .pi * CGFloat(shakesPerUnit)),
            y: 0))
    }
}

extension View {
    func shake(_ trigger: Binding<Bool>) -> some View {
        self.modifier(ShakeModifier(trigger: trigger))
    }
}

struct ShakeModifier: ViewModifier {
    @Binding var trigger: Bool
    @State private var animatableData: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .modifier(ShakeEffect(animatableData: animatableData))
            .onChange(of: trigger) { _, newValue in
                if newValue {
                     withAnimation(.default) {
                        animatableData = 1
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        animatableData = 0
                        trigger = false
                    }
                }
            }
    }
}
