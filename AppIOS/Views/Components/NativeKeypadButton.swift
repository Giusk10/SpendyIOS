import SwiftUI

struct NativeKeypadButton: View {
    let text: String
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(text).font(.title.weight(.medium))
                .frame(maxWidth: .infinity, minHeight: 64)
                .foregroundStyle(Color.spendyText)
                .background(Color.spendySurface, in: RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }
}

struct PinEntryPad: View {
    let count: Int
    let error: Bool
    var biometricAction: (() -> Void)? = nil
    let onDigit: (String) -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            HStack(spacing: 18) {
                ForEach(0..<6) { index in
                    Circle()
                        .fill(index < count ? Color.spendyPrimary : Color.spendyBackgroundDeep)
                        .frame(width: 14, height: 14)
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("PIN")
            .accessibilityValue("\(count) di 6 cifre inserite")
            if error {
                Text("PIN non corretto. Riprova.")
                    .font(.subheadline).foregroundStyle(Color.spendyRed)
            }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                ForEach(1...9, id: \.self) { number in
                    NativeKeypadButton(text: String(number)) { onDigit(String(number)) }
                }
                if let biometricAction {
                    Button("Sblocca con biometria", systemImage: "faceid", action: biometricAction)
                        .labelStyle(.iconOnly).font(.title2)
                        .frame(maxWidth: .infinity, minHeight: 64)
                } else {
                    Color.clear.frame(height: 64).accessibilityHidden(true)
                }
                NativeKeypadButton(text: "0") { onDigit("0") }
                Button("Cancella ultima cifra", systemImage: "delete.left", action: onDelete)
                    .labelStyle(.iconOnly).font(.title2)
                    .frame(maxWidth: .infinity, minHeight: 64)
            }
        }
        .frame(maxWidth: 340)
    }
}

struct PinHeader: View {
    let title: String
    let subtitle: String
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "lock.shield")
                .font(.largeTitle).foregroundStyle(Color.spendyPrimary)
                .accessibilityHidden(true)
            Text(title).font(.title2.bold()).accessibilityAddTraits(.isHeader)
            Text(subtitle).font(.subheadline).foregroundStyle(Color.spendySecondaryText)
        }
        .multilineTextAlignment(.center)
    }
}
