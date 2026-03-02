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
            AnimatedGradientBackground()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 36) {

                    // MARK: - Header
                    VStack(spacing: 16) {
                        ZStack {
                            // Outer glow ring
                            Circle()
                                .fill(Color.spendyPrimary.opacity(0.12))
                                .frame(width: 130, height: 130)
                                .blur(radius: 16)

                            // Logo background circle
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.spendyPrimary.opacity(0.18),
                                            Color.spendyAccent.opacity(0.12)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 110, height: 110)

                            // Inner border ring
                            Circle()
                                .stroke(Color.spendyGradientBorder, lineWidth: 1.5)
                                .frame(width: 110, height: 110)

                            Image("SpendyLogo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 72, height: 72)
                                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                                .shadow(color: Color.spendyShadowPrimary, radius: 8, x: 0, y: 4)
                        }
                        .scaleEffect(animateContent ? 1 : 0.8)
                        .opacity(animateContent ? 1 : 0)
                        .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.05), value: animateContent)

                        VStack(spacing: 6) {
                            Text(isLoginMode ? "Bentornato!" : "Crea Account")
                                .font(.system(size: 30, weight: .bold, design: .rounded))
                                .foregroundColor(.spendyText)
                                .contentTransition(.numericText())
                                .animation(.easeInOut(duration: 0.25), value: isLoginMode)

                            Text(
                                isLoginMode
                                    ? "Accedi per gestire le tue spese"
                                    : "Registrati per iniziare"
                            )
                            .font(.subheadline)
                            .foregroundColor(.spendySecondaryText)
                            .contentTransition(.opacity)
                            .animation(.easeInOut(duration: 0.25), value: isLoginMode)
                        }
                        .opacity(animateContent ? 1 : 0)
                        .offset(y: animateContent ? 0 : 16)
                        .animation(.easeOut(duration: 0.45).delay(0.1), value: animateContent)
                    }
                    .padding(.top, 52)

                    // MARK: - Mode Selector
                    AuthModeSelector(isLoginMode: $isLoginMode)
                        .opacity(animateContent ? 1 : 0)
                        .offset(y: animateContent ? 0 : 12)
                        .animation(.easeOut(duration: 0.45).delay(0.15), value: animateContent)
                        .padding(.horizontal, 24)

                    // MARK: - Form Card
                    SpendyCard(style: .elevated, padding: 24, cornerRadius: 28) {
                        VStack(spacing: 16) {

                            // Username field
                            SpendyTextField(
                                label: isLoginMode ? "Username o email" : "Username",
                                text: $username,
                                icon: "person.fill",
                                keyboardType: .default,
                                autocapitalization: .never
                            )
                            .focused($focusedField, equals: .username)

                            // Password field
                            SpendyTextField(
                                label: "Password",
                                text: $password,
                                icon: "lock.fill",
                                isSecure: true,
                                textContentType: .password
                            )
                            .focused($focusedField, equals: .password)

                            if !isLoginMode {
                                SpendyTextField(
                                    label: "Email",
                                    text: $email,
                                    icon: "envelope.fill",
                                    keyboardType: .emailAddress,
                                    textContentType: .emailAddress,
                                    autocapitalization: .never
                                )
                                .focused($focusedField, equals: .email)
                                .transition(.move(edge: .top).combined(with: .opacity))

                                HStack(spacing: 12) {
                                    SpendyTextField(
                                        label: "Nome",
                                        text: $name,
                                        icon: "person.text.rectangle",
                                        textContentType: .givenName
                                    )
                                    .focused($focusedField, equals: .name)

                                    SpendyTextField(
                                        label: "Cognome",
                                        text: $surname,
                                        icon: "person.text.rectangle",
                                        textContentType: .familyName
                                    )
                                    .focused($focusedField, equals: .surname)
                                }
                                .transition(.move(edge: .top).combined(with: .opacity))
                            }

                            // MARK: - Error Banner
                            if let error = authManager.errorMessage {
                                HStack(spacing: 10) {
                                    Image(systemName: "exclamationmark.circle.fill")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(.spendyRed)

                                    Text(error)
                                        .font(.subheadline)
                                        .foregroundColor(.spendyRed)
                                        .fixedSize(horizontal: false, vertical: true)

                                    Spacer()
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(Color.spendyRedLight)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                .stroke(Color.spendyRed.opacity(0.25), lineWidth: 1)
                                        )
                                )
                                .transition(.move(edge: .top).combined(with: .opacity))
                            }

                            // MARK: - Primary Action Button
                            SpendyButton(
                                isLoginMode ? "Accedi" : "Registrati",
                                isLoading: authManager.isLoading,
                                leadingIcon: isLoginMode ? "arrow.right.circle.fill" : "person.badge.plus"
                            ) {
                                handleAction()
                            }
                            .padding(.top, 4)

                            // MARK: - Toggle Mode Link
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
                            .padding(.top, 4)
                        }
                    }
                    .padding(.horizontal, 20)
                    .opacity(animateContent ? 1 : 0)
                    .offset(y: animateContent ? 0 : 24)
                    .animation(.easeOut(duration: 0.45).delay(0.2), value: animateContent)

                    Spacer(minLength: 40)
                }
            }
        }
        .onAppear {
            animateContent = true
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

// MARK: - Auth Mode Selector

/// Animated pill-style segmented control for switching between Login and Register modes.
private struct AuthModeSelector: View {

    @Binding var isLoginMode: Bool
    @Namespace private var pillNamespace

    private let options: [(label: String, icon: String, isLogin: Bool)] = [
        ("Accedi", "arrow.right.circle.fill", true),
        ("Registrati", "person.badge.plus", false)
    ]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(options, id: \.label) { option in
                Button(action: {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                        isLoginMode = option.isLogin
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: option.icon)
                            .font(.system(size: 13, weight: .semibold))
                        Text(option.label)
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(
                        isLoginMode == option.isLogin ? .white : .spendySecondaryText
                    )
                    .frame(maxWidth: .infinity)
                    .frame(height: 42)
                    .background {
                        if isLoginMode == option.isLogin {
                            Capsule()
                                .fill(Color.spendyGradientDeep)
                                .shadow(color: Color.spendyPrimary.opacity(0.30), radius: 8, x: 0, y: 4)
                                .matchedGeometryEffect(id: "pill", in: pillNamespace)
                        }
                    }
                }
                .buttonStyle(.plain)
                .animation(.spring(response: 0.4, dampingFraction: 0.75), value: isLoginMode)
            }
        }
        .padding(4)
        .background(
            Capsule()
                .fill(Color.spendyBackgroundDark)
                .overlay(
                    Capsule()
                        .stroke(Color.spendyBorderSubtle, lineWidth: 0.5)
                )
        )
    }
}

