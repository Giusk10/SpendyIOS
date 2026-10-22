import SwiftUI

struct AuthView: View {
    @ObservedObject private var authManager = AuthManager.shared
    @State private var isLoginMode = true
    @State private var username = ""
    @State private var password = ""
    @State private var email = ""
    @State private var name = ""
    @State private var surname = ""
    @State private var successMessage: String?

    private var canSubmit: Bool {
        !username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !password.isEmpty
            && (isLoginMode || (!email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                               && !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                               && !surname.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 12) {
                        Image("SpendyLogo").resizable().scaledToFit()
                            .frame(width: 60, height: 60)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .accessibilityHidden(true)
                        Text("Spendy").font(.largeTitle.bold()).accessibilityAddTraits(.isHeader).foregroundStyle(Color.spendyPrimary)
                        Text(isLoginMode ? "Le tue finanze, in ordine." : "Inizia a gestire le tue spese.")
                            .font(.title3).foregroundStyle(Color.spendySecondaryText)
                    }
                    .padding(.top, 24)
                    Picker("Accesso", selection: $isLoginMode) {
                        Text("Accedi").tag(true)
                        Text("Registrati").tag(false)
                    }
                    .pickerStyle(.segmented)
                    VStack(spacing: 18) {
                        SpendyTextField(label: isLoginMode ? "Username o email" : "Username",
                                        text: $username, icon: "person", textContentType: .username,
                                        autocapitalization: .never)
                        SpendyTextField(label: "Password", text: $password, icon: "lock",
                                        isSecure: true, textContentType: isLoginMode ? .password : .newPassword)
                        if !isLoginMode {
                            SpendyTextField(label: "Email", text: $email, icon: "envelope",
                                            keyboardType: .emailAddress, textContentType: .emailAddress,
                                            autocapitalization: .never)
                            SpendyTextField(label: "Nome", text: $name, textContentType: .givenName,
                                            autocapitalization: .words)
                            SpendyTextField(label: "Cognome", text: $surname, textContentType: .familyName,
                                            autocapitalization: .words)
                        }
                    }
                    if let error = authManager.errorMessage { SpendyMessage(message: error) }
                    if let successMessage { SpendyMessage(message: successMessage, isError: false) }
                    SpendyButton(isLoginMode ? "Accedi" : "Crea account",
                                 isLoading: authManager.isLoading, isDisabled: !canSubmit,
                                 leadingIcon: "arrow.right") { handleAction() }
                }
                .frame(maxWidth: 460)
                .padding(24)
                .frame(maxWidth: .infinity)
            }
            .background(Color.spendyBackground)
            .scrollDismissesKeyboard(.interactively)
            .disabled(authManager.isLoading)
            .onChange(of: isLoginMode) { _, _ in
                authManager.errorMessage = nil
                if !isLoginMode { successMessage = nil }
            }
        }
    }

    private func handleAction() {
        guard canSubmit, !authManager.isLoading else { return }
        Task {
            if isLoginMode {
                _ = await authManager.login(username: username, password: password)
            } else {
                let success = await authManager.register(username: username, password: password,
                                                        email: email, name: name, surname: surname)
                if success && authManager.authState == .unauthenticated {
                    isLoginMode = true
                    successMessage = "Account creato. Accedi per continuare."
                }
            }
        }
    }
}

#Preview("Accesso • Light") { AuthView().preferredColorScheme(.light) }
#Preview("Accesso • Dark") { AuthView().preferredColorScheme(.dark) }
