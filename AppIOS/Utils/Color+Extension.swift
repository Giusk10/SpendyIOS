import SwiftUI
import UIKit

/// Semantic colors resolve at render time, including live system appearance changes.
extension Color {
    static let spendyPrimary = adaptive(light: 0x4F46E5, dark: 0xB5AEFF)
    static let spendyPrimaryDark = adaptive(light: 0x4338CA, dark: 0x5145CD)

    static let spendyAccent = spendyPrimary

    static let spendyBackground = Color(uiColor: .systemGroupedBackground)

    static let spendyBackgroundDeep = Color(uiColor: .systemFill)
    static let spendySurface = Color(uiColor: .secondarySystemGroupedBackground)

    static let spendyText = Color.primary
    static let spendySecondaryText = adaptive(light: 0x626270, dark: 0xB5B5C2)

    static let spendyRed = adaptive(light: 0xB42332, dark: 0xFF9BA4)
    static let spendyGreen = adaptive(light: 0x08734E, dark: 0x6EDBB0)
    static let spendyBlue = adaptive(light: 0x245EBA, dark: 0x93BEFF)
    static let spendyOrange = adaptive(light: 0x925300, dark: 0xF6C479)
    static let spendyPink = adaptive(light: 0xAA286C, dark: 0xF6A2CB)
    static let spendyCyan = adaptive(light: 0x006C7A, dark: 0x77D9E7)
    static let spendyRedLight = spendyRed.opacity(0.10)
    static let spendyGreenLight = spendyGreen.opacity(0.10)

    static let spendyBorderSubtle = Color(uiColor: .separator).opacity(0.35)
    static let spendyBorderMedium = adaptive(light: 0x80808B, dark: 0x888894)

    private static func adaptive(light: UInt32, dark: UInt32) -> Color {
        Color(uiColor: UIColor { traits in
            let hex = traits.userInterfaceStyle == .dark ? dark : light
            return UIColor(red: CGFloat((hex >> 16) & 255) / 255,
                           green: CGFloat((hex >> 8) & 255) / 255,
                           blue: CGFloat(hex & 255) / 255, alpha: 1)
        })
    }

}

enum SpendyLayout {
    static let spacing: CGFloat = 16
    static let pagePadding: CGFloat = 20
    static let cornerRadius: CGFloat = 16
    static let contentWidth: CGFloat = 640
}
