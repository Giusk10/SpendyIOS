import SwiftUI

struct LockView: View {
    @ObservedObject private var authManager = AuthManager.shared
    @State private var pin = ""
    @State private var showError = false
    @State private var showingLogout = false
    @State private var supportsBiometrics = false

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 24) {
                    Spacer(minLength: 0)
                    PinHeader(title: "Bentornato in Spendy",
                              subtitle: "Inserisci il PIN per accedere alle tue finanze.",
                              showsProfileAvatar: true, user: authManager.currentUser)
                    Spacer(minLength: 0)
                    PinEntryPad(count: pin.count, error: showError,
                                circularDiameter: keyDiameter(in: geometry.size),
                                biometricAction: supportsBiometrics ? { authManager.unlockWithBiometrics() } : nil,
                                onDigit: addDigit, onDelete: {
                        if !pin.isEmpty { pin.removeLast() }
                        showError = false
                    })
                    .disabled(authManager.isBiometricAuthenticationInProgress)
                    if authManager.isBiometricAuthenticationInProgress {
                        ProgressView("Autenticazione…")
                    }
                    Button("Hai dimenticato il PIN?") { showingLogout = true }
                        .font(.subheadline).frame(minHeight: 44)
                }
                .padding(24)
                .frame(maxWidth: .infinity)
                .frame(minHeight: geometry.size.height)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .background(Color.spendyBackground)
        .task {
            supportsBiometrics = authManager.canUseBiometrics()
            if supportsBiometrics { authManager.unlockWithBiometrics() }
        }
        .confirmationDialog("Accedi di nuovo al tuo account", isPresented: $showingLogout,
                            titleVisibility: .visible) {
            Button("Esci e accedi di nuovo", role: .destructive) { authManager.logout() }
        } message: {
            Text("Il PIN verrà rimosso. Le transazioni del tuo account resteranno salvate.")
        }
    }

    // Size the keys from the safe-area viewport; scrolling handles short windows
    // and accessibility text without shrinking touch targets.
    private func keyDiameter(in size: CGSize) -> CGFloat {
        min(96, max(64, (size.width - 96) / 3), max(72, size.height * 0.12))
    }

    private func addDigit(_ digit: String) {
        guard pin.count < 6 else { return }
        showError = false
        pin.append(digit)
        if pin.count == 6 {
            showError = !authManager.unlock(with: pin)
            pin = ""
        }
    }
}

#Preview("Blocco • Dark") { LockView().preferredColorScheme(.dark) }
#Preview("Blocco • Light compatto", traits: .fixedLayout(width: 320, height: 568)) {
    LockView().preferredColorScheme(.light)
}
#Preview("Blocco • Accessibilità") {
    LockView().preferredColorScheme(.dark).dynamicTypeSize(.accessibility3)
}
