import SwiftUI

struct AuthView: View {
    @StateObject private var authManager = AuthManager.shared
    @State private var isLoginMode = true
    @State private var username = ""
    @State private var password = ""
    @State private var email = ""
    @State private var name = ""
    @State private var surname = ""
    @State private var animateContent = false

    enum Field: Hashable {
        case username, password, email, name, surname
    }

    @FocusState private var focusedField: Field?

    var body: some View {
        ZStack {
            Color.spendyBackground
                .ignoresSafeArea()

            Circle()
                .fill(Color.spendyPrimary.opacity(0.15))
                .frame(width: 300)
                .blur(radius: 60)
                .offset(x: -150, y: -300)

            Circle()
                .fill(Color.spendyAccent.opacity(0.12))
                .frame(width: 250)
                .blur(radius: 50)
                .offset(x: 150, y: 400)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 32) {
                    VStack(spacing: 20) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.spendyPrimary.opacity(0.2),
                                            Color.spendyAccent.opacity(0.1),
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 120, height: 120)

                            Image("SpendyLogo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 80, height: 80)
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                        }
                        .scaleEffect(animateContent ? 1 : 0.8)
                        .opacity(animateContent ? 1 : 0)

                        VStack(spacing: 8) {
                            Text(isLoginMode ? "Bentornato!" : "Crea Account")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(.spendyText)

                            Text(
                                isLoginMode
                                    ? "Accedi per gestire le tue spese" : "Registrati per iniziare"
                            )
                            .font(.body)
                            .foregroundColor(.spendySecondaryText)
                        }
                        .opacity(animateContent ? 1 : 0)
                        .offset(y: animateContent ? 0 : 20)
                    }
                    .padding(.top, 40)

                    VStack(spacing: 20) {
                        ModernTextField(
                            icon: "person.fill",
                            placeholder: isLoginMode ? "Username o email" : "Username",
                            text: $username,
                            isSecure: false
                        )
                        .focused($focusedField, equals: .username)
                        .textInputAutocapitalization(.never)

                        ModernTextField(
                            icon: "lock.fill",
                            placeholder: "Password",
                            text: $password,
                            isSecure: true
                        )
                        .focused($focusedField, equals: .password)

                        if !isLoginMode {
                            ModernTextField(
                                icon: "envelope.fill",
                                placeholder: "Email",
                                text: $email,
                                isSecure: false
                            )
                            .focused($focusedField, equals: .email)
                            .textInputAutocapitalization(.never)
                            .keyboardType(.emailAddress)

                            HStack(spacing: 12) {
                                ModernTextField(
                                    icon: "person.text.rectangle",
                                    placeholder: "Nome",
                                    text: $name,
                                    isSecure: false
                                )
                                .focused($focusedField, equals: .name)

                                ModernTextField(
                                    icon: "person.text.rectangle",
                                    placeholder: "Cognome",
                                    text: $surname,
                                    isSecure: false
                                )
                                .focused($focusedField, equals: .surname)
                            }
                        }

                        if let error = authManager.errorMessage {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .foregroundColor(.spendyRed)
                                Text(error)
                                    .font(.subheadline)
                                    .foregroundColor(.spendyRed)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(Color.spendyRed.opacity(0.1))
                            .cornerRadius(12)
                        }

                        Button(action: handleAction) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.spendyGradient)
                                    .shadow(
                                        color: Color.spendyPrimary.opacity(0.4), radius: 12, x: 0,
                                        y: 6)

                                if authManager.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(1.2)
                                } else {
                                    HStack(spacing: 8) {
                                        Text(isLoginMode ? "Accedi" : "Registrati")
                                            .font(.headline)
                                            .fontWeight(.bold)
                                        Image(systemName: "arrow.right")
                                            .font(.system(size: 16, weight: .bold))
                                    }
                                    .foregroundColor(.white)
                                }
                            }
                            .frame(height: 56)
                        }
                        .disabled(authManager.isLoading)
                        .padding(.top, 8)

                        Button(action: {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                isLoginMode.toggle()
                            }
                        }) {
                            HStack(spacing: 4) {
                                Text(isLoginMode ? "Non hai un account?" : "Hai già un account?")
                                    .foregroundColor(.spendySecondaryText)
                                Text(isLoginMode ? "Registrati" : "Accedi")
                                    .fontWeight(.bold)
                                    .foregroundStyle(Color.spendyGradient)
                            }
                            .font(.subheadline)
                        }
                        .padding(.top, 8)
                    }
                    .padding(24)
                    .background {
                        RoundedRectangle(cornerRadius: 28)
                            .fill(.ultraThinMaterial)
                            .shadow(color: Color.black.opacity(0.08), radius: 20, x: 0, y: 10)
                    }
                    .padding(.horizontal, 20)
                    .opacity(animateContent ? 1 : 0)
                    .offset(y: animateContent ? 0 : 30)

                    Spacer(minLength: 40)
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                animateContent = true
            }
        }
    }

    private func handleAction() {
        focusedField = nil
        Task {
            if isLoginMode {
                _ = await authManager.login(username: username, password: password)
            } else {
                _ = await authManager.register(
                    username: username, password: password, email: email, name: name,
                    surname: surname)
            }
        }
    }
}

struct ModernTextField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    let isSecure: Bool
    @State private var isPasswordVisible = false
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(isFocused ? .spendyPrimary : .spendySecondaryText)
                .frame(width: 24)

            if isSecure && !isPasswordVisible {
                SecureField(placeholder, text: $text)
                    .focused($isFocused)
            } else {
                TextField(placeholder, text: $text)
                    .focused($isFocused)
            }

            if isSecure {
                Button(action: { isPasswordVisible.toggle() }) {
                    Image(systemName: isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.spendySecondaryText)
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(isFocused ? Color.spendyPrimary : Color.clear, lineWidth: 2)
        )
        .shadow(
            color: isFocused ? Color.spendyPrimary.opacity(0.15) : Color.black.opacity(0.04),
            radius: isFocused ? 8 : 4, x: 0, y: 2
        )
        .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
}
