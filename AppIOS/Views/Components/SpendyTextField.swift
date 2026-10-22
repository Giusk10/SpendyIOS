import SwiftUI

/// Persistent labels remain legible when editing and at accessibility text sizes.
struct SpendyTextField: View {
    let label: String
    @Binding var text: String
    var icon: String? = nil
    var isSecure = false
    var keyboardType: UIKeyboardType = .default
    var textContentType: UITextContentType? = nil
    var autocapitalization: TextInputAutocapitalization = .sentences
    var error: String? = nil
    @FocusState private var isFocused: Bool
    @State private var isPasswordVisible = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label).font(.subheadline.weight(.medium)).foregroundStyle(Color.spendySecondaryText)
            HStack(spacing: 12) {
                if let icon {
                    Image(systemName: icon).foregroundStyle(Color.spendyPrimary)
                        .accessibilityHidden(true)
                }
                Group {
                    if isSecure && !isPasswordVisible {
                        SecureField(label, text: $text, prompt: Text(label).foregroundStyle(Color.spendySecondaryText))
                    } else {
                        TextField(label, text: $text, prompt: Text(label).foregroundStyle(Color.spendySecondaryText))
                    }
                }
                .font(.body)
                .focused($isFocused)
                .keyboardType(keyboardType)
                .textContentType(textContentType)
                .textInputAutocapitalization(isSecure ? .never : autocapitalization)
                .autocorrectionDisabled(isSecure || textContentType == .username || keyboardType == .emailAddress)
                .accessibilityLabel(label)
                .submitLabel(.done)
                .onSubmit { isFocused = false }
                if isSecure {
                    Button {
                        isPasswordVisible.toggle()
                        isFocused = true
                    } label: {
                        Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                            .frame(minWidth: 44, minHeight: 44)
                    }
                    .accessibilityLabel(isPasswordVisible ? "Nascondi password" : "Mostra password")
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, isSecure ? 4 : 16)
            .background(Color.spendySurface, in: RoundedRectangle(cornerRadius: 12))
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(error != nil ? Color.spendyRed :
                                  (isFocused ? Color.spendyPrimary : Color.spendyBorderMedium),
                                  lineWidth: isFocused ? 1.5 : 1)
            }
            if let error {
                Text(error).font(.caption).foregroundStyle(Color.spendyRed)
            }
        }
        .tint(.spendyPrimary)
    }
}
