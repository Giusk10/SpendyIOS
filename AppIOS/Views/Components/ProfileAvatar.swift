import SwiftUI

/// Shared with the profile so both surfaces use the same initials and typography.
struct ProfileAvatar: View {
    let user: User?
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
            if let user {
                Text(user.initials)
            } else {
                Image(systemName: "person.crop.circle")
            }
        }
        .font(.title2.bold())
        .foregroundStyle(Color.spendyPrimary)
        .minimumScaleFactor(0.5)
        .lineLimit(1)
        .frame(width: 64, height: 64)
    }
}
