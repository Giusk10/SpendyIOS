import SwiftUI
import UIKit

struct NativeKeypadButton: View {
    let text: String
    let action: () -> Void
    @State private var isPressed = false

    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.18, dampingFraction: 0.6)) {
                isPressed = true
            }
            action()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.14) {
                withAnimation(.spring(response: 0.2, dampingFraction: 0.65)) {
                    isPressed = false
                }
            }
        }) {
            ZStack {
                Circle()
                    .fill(
                        isPressed
                            ? Color.spendyPrimary.opacity(0.15)
                            : Color.spendySurface
                    )
                    .frame(width: 72, height: 72)
                    .shadow(
                        color: Color.spendyShadowCard,
                        radius: isPressed ? 2 : 6,
                        x: 0,
                        y: isPressed ? 1 : 3
                    )
                    .overlay(
                        Circle()
                            .stroke(Color.spendyBorderSubtle, lineWidth: 0.5)
                    )

                Text(text)
                    .font(.system(size: 28, weight: .regular, design: .rounded))
                    .foregroundColor(.spendyText)
            }
            .scaleEffect(isPressed ? 0.93 : 1.0)
            .animation(.spring(response: 0.18, dampingFraction: 0.6), value: isPressed)
        }
        .buttonStyle(.plain)
    }
}
