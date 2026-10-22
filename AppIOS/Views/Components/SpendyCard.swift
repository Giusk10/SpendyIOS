import SwiftUI

struct SpendyCard<Content: View>: View {
    var padding: CGFloat = SpendyLayout.spacing
    var cornerRadius: CGFloat = SpendyLayout.cornerRadius
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(padding)
            .background(Color.spendySurface, in: RoundedRectangle(cornerRadius: cornerRadius))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(Color.spendyBorderSubtle, lineWidth: 0.5)
            }
    }
}
