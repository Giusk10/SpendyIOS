import SwiftUI

struct SpendyMessage: View {
    let message: String
    var isError = true

    var body: some View {
        Label(message, systemImage: isError ? "exclamationmark.circle" : "checkmark.circle")
            .font(.subheadline)
            .foregroundStyle(isError ? Color.spendyRed : Color.spendyGreen)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(isError ? Color.spendyRedLight : Color.spendyGreenLight,
                        in: RoundedRectangle(cornerRadius: 12))
            .accessibilityElement(children: .combine)
    }
}

struct SpendyEmptyState: View {
    let title: String
    let message: String
    var icon = "tray"

    var body: some View {
        ContentUnavailableView {
            Label(title, systemImage: icon)
        } description: {
            Text(message)
        }
        .frame(maxWidth: .infinity)
    }
}
