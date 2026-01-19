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
            // Background blur or color
            Color.black.opacity(0.9)
                .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                VStack(spacing: 16) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.white)
                    
                    Text("App Bloccata")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Text("Inserisci il PIN per sbloccare")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                // PIN Dots
                HStack(spacing: 20) {
                    ForEach(0..<4) { index in
                        Circle()
                            .fill(index < pin.count ? Color.white : Color.gray.opacity(0.3))
                            .frame(width: 20, height: 20)
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: 1)
                            )
                    }
                }
                .shake($showError)
                
                Spacer()
                
                // Numpad
                LazyVGrid(columns: columns, spacing: 30) {
                    ForEach(1...9, id: \.self) { number in
                        NumberButton(number: "\(number)") {
                            addDigit("\(number)")
                        }
                    }
                    
                    // Empty space for alignment
                    Color.clear
                        .frame(width: 80, height: 80)
                    
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
                                
                Button(action: {
                    authManager.unlockWithBiometrics()
                }) {
                    HStack {
                        Image(systemName: "faceid")
                        Text("Usa FaceID/TouchID")
                    }
                    .foregroundColor(.blue)
                    .padding(.top, 20)
                }
                
                Spacer()
            }
        }
        .onAppear {
            authManager.unlockWithBiometrics()
        }
    }
    
    private func addDigit(_ digit: String) {
        if pin.count < 4 {
            pin.append(digit)
            if pin.count == 4 {
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
            // Success handled by AuthManager state change
            pin = ""
        } else {
            // Failure
            showError = true
            pin = ""
            
            // Haptic feedack
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
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
                    // Reset after animation
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        animatableData = 0
                        trigger = false
                    }
                }
            }
    }
}

struct NumberButton: View {
    let number: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(number)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(width: 80, height: 80)
                .background(Color.white.opacity(0.1))
                .clipShape(Circle())
        }
    }
}
