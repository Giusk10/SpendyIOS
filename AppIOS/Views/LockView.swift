import SwiftUI

struct LockView: View {
    @ObservedObject private var authManager = AuthManager.shared
    @State private var pin = ""
    @State private var showError = false
    @State private var showingLogout = false
    @State private var supportsBiometrics = false

    private var greetingTitle: String {
        guard let name = authManager.currentUser?.name,
              !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return "Bentornato in Spendy"
        }
        let hour = Calendar.current.component(.hour, from: Date())
        let isItalian = Locale.current.language.languageCode?.identifier == "it"
        let salutation: String
        if hour >= 5 && hour < 12 {
            salutation = isItalian ? "Buongiorno" : "Good morning"
        } else if hour >= 12 && hour < 18 {
            salutation = isItalian ? "Buon pomeriggio" : "Good afternoon"
        } else {
            salutation = isItalian ? "Buonasera" : "Good evening"
        }
        return "\(salutation), \(name)"
    }

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 24) {
                    Spacer(minLength: 12)
                    PinHeader(title: greetingTitle,
                              subtitle: nil,
                              showsProfileAvatar: true,
                              user: authManager.currentUser,
                              avatarSize: keyDiameter(in: geometry.size))
                    Spacer(minLength: 8)
                    PinEntryPad(count: pin.count,
                                error: showError,
                                circularDiameter: keyDiameter(in: geometry.size),
                                biometricAction: supportsBiometrics ? { authManager.unlockWithBiometrics() } : nil,
                                onDigit: addDigit,
                                onDelete: {
                        if !pin.isEmpty { pin.removeLast() }
                        showError = false
                    })
                    .disabled(authManager.isBiometricAuthenticationInProgress)
                    if authManager.isBiometricAuthenticationInProgress {
                        ProgressView("Autenticazione…")
                    }
                    Spacer(minLength: 16)
                    Button("Hai dimenticato il PIN?") { showingLogout = true }
                        .font(.subheadline)
                        .foregroundStyle(Color.spendySecondaryText)
                        .frame(minHeight: 44)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity)
                .frame(minHeight: geometry.size.height)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .background(Color.spendyBackground)
        .task {
            supportsBiometrics = authManager.canUseBiometrics()
            if supportsBiometrics { authManager.unlockWithBiometrics() }
            if authManager.currentUser == nil {
                await authManager.fetchUserProfile()
            }
        }
        .confirmationDialog("Accedi di nuovo al tuo account", isPresented: $showingLogout,
                            titleVisibility: .visible) {
            Button("Esci e accedi di nuovo", role: .destructive) { authManager.logout() }
        } message: {
            Text("Il PIN verrà rimosso. Le transazioni del tuo account resteranno salvate.")
        }
    }

    private func keyDiameter(in size: CGSize) -> CGFloat {
        min(80, max(68, (size.width - 120) / 3))
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
