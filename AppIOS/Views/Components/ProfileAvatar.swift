import SwiftUI

/// Shared with the profile and lock screens so both surfaces use the same initials and typography.
struct ProfileAvatar: View {
    let user: User?
    var size: CGFloat = 64
    var usesGlass = false

    var body: some View {
        Group {
            if usesGlass {
                avatar.modifier(PinCircularSurface())
            } else {
                avatar.background(Color.spendyPrimary.opacity(0.10), in: Circle())
            }
        }
        .accessibilityHidden(true)
    }

    private var avatar: some View {
        Group {
            if let user, !user.initials.isEmpty {
                Text(user.initials)
            } else {
                Image(systemName: "person.crop.circle")
            }
        }
        .font(size >= 64 ? .title2.weight(.semibold) : .headline.weight(.semibold))
        .foregroundStyle(usesGlass ? Color.spendyText : Color.spendyPrimary)
        .minimumScaleFactor(0.5)
        .lineLimit(1)
        .frame(width: size, height: size)
    }
}
