import SwiftUI

// MARK: - SpendyTextField

/// A unified text field with floating label animation, optional left icon,
/// secure-text toggle for passwords, focus-state colored border, and error state.
///
/// Usage:
/// ```swift
/// @State private var email = ""
/// @FocusState private var emailFocused: Bool
///
/// SpendyTextField(
///     label: "Email",
///     text: $email,
///     icon: "envelope.fill",
///     isFocused: $emailFocused,
///     error: formError
/// )
/// ```
struct SpendyTextField: View {

    // MARK: - Configuration

    let label: String
    @Binding var text: String
    var icon: String?
    var isSecure: Bool
    var keyboardType: UIKeyboardType
    var textContentType: UITextContentType?
    var autocapitalization: TextInputAutocapitalization
    var error: String?

    // MARK: - Internal State

    @FocusState private var isFocused: Bool
    @State private var isPasswordVisible: Bool = false

    // MARK: - Initializer

    init(
        label: String,
        text: Binding<String>,
        icon: String? = nil,
        isSecure: Bool = false,
        keyboardType: UIKeyboardType = .default,
        textContentType: UITextContentType? = nil,
        autocapitalization: TextInputAutocapitalization = .sentences,
        error: String? = nil
    ) {
        self.label = label
        self._text = text
        self.icon = icon
        self.isSecure = isSecure
        self.keyboardType = keyboardType
        self.textContentType = textContentType
        self.autocapitalization = autocapitalization
        self.error = error
    }

    // MARK: - Computed State

    private var isFloating: Bool {
        isFocused || !text.isEmpty
    }

    private var borderColor: Color {
        if error != nil { return .spendyRed }
        return isFocused ? .spendyPrimary : .clear
    }

    private var shadowColor: Color {
        if error != nil { return Color.spendyRed.opacity(0.15) }
        return isFocused ? Color.spendyPrimary.opacity(0.15) : Color.spendyShadowNear
    }

    private var shadowRadius: CGFloat {
        isFocused || error != nil ? 8 : 4
    }

    private var iconColor: Color {
        if error != nil { return .spendyRed }
        return isFocused ? .spendyPrimary : .spendyTertiaryText
    }

    private var labelColor: Color {
        if error != nil { return .spendyRed }
        return isFocused ? .spendyPrimary : .spendyTertiaryText
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            fieldContainer
            if let error {
                errorLabel(error)
            }
        }
    }

    // MARK: - Field Container

    private var fieldContainer: some View {
        HStack(spacing: 12) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(iconColor)
                    .frame(width: 22)
                    .animation(.easeInOut(duration: 0.2), value: isFocused)
            }

            ZStack(alignment: .leading) {
                // Floating label
                Text(label)
                    .font(isFloating
                          ? .system(size: 11, weight: .semibold)
                          : .system(size: 15, weight: .regular))
                    .foregroundColor(labelColor)
                    .offset(y: isFloating ? -14 : 0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.75), value: isFloating)

                // Input field (sits below the label when floating)
                Group {
                    if isSecure && !isPasswordVisible {
                        SecureField("", text: $text)
                            .focused($isFocused)
                            .textContentType(textContentType)
                    } else {
                        TextField("", text: $text)
                            .focused($isFocused)
                            .keyboardType(keyboardType)
                            .textInputAutocapitalization(autocapitalization)
                            .textContentType(textContentType)
                    }
                }
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(.spendyText)
                .opacity(isFloating ? 1 : 0)
                .offset(y: isFloating ? 8 : 0)
                .animation(.spring(response: 0.3, dampingFraction: 0.75), value: isFloating)
            }
            .frame(height: 44)

            if isSecure {
                Button(action: { isPasswordVisible.toggle() }) {
                    Image(systemName: isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(.spendyTertiaryText)
                }
                .buttonStyle(.plain)
            }

            if let error, !error.isEmpty, !isSecure {
                Image(systemName: "exclamationmark.circle.fill")
                    .font(.system(size: 15))
                    .foregroundColor(.spendyRed)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
        .frame(height: 60)
        .background(Color.spendySurface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(borderColor, lineWidth: 1.8)
        )
        .shadow(color: shadowColor, radius: shadowRadius, x: 0, y: 2)
        .animation(.easeInOut(duration: 0.2), value: isFocused)
        .animation(.easeInOut(duration: 0.2), value: error)
        .contentShape(Rectangle())
        .onTapGesture {
            isFocused = true
        }
    }

    private func errorLabel(_ message: String) -> some View {
        HStack(spacing: 4) {
            Text(message)
                .font(.caption)
                .foregroundColor(.spendyRed)
        }
        .padding(.leading, 4)
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}

// MARK: - Preview

#Preview("SpendyTextField States") {
    ScrollView {
        VStack(spacing: 20) {
            SpendyTextField(
                label: "Email",
                text: .constant(""),
                icon: "envelope.fill",
                keyboardType: .emailAddress,
                autocapitalization: .never
            )

            SpendyTextField(
                label: "Username",
                text: .constant("gius03"),
                icon: "person.fill",
                autocapitalization: .never
            )

            SpendyTextField(
                label: "Password",
                text: .constant("secret"),
                icon: "lock.fill",
                isSecure: true
            )

            SpendyTextField(
                label: "Email",
                text: .constant("bad@"),
                icon: "envelope.fill",
                keyboardType: .emailAddress,
                autocapitalization: .never,
                error: "Inserisci un'email valida"
            )
        }
        .padding(24)
    }
    .background(Color.spendyBackground)
}
