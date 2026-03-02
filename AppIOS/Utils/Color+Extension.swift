import SwiftUI

extension Color {

    // MARK: - Primary Brand Colors
    // Deeper, richer indigo/violet identity
    static let spendyPrimary = Color(hex: "4F46E5")       // Indigo 600 — richer base
    static let spendyPrimaryDark = Color(hex: "3730A3")   // Indigo 800 — deep anchor
    static let spendyPrimaryLight = Color(hex: "6366F1")  // Indigo 500 — lighter highlight
    static let spendyAccent = Color(hex: "7C3AED")        // Violet 600 — slightly desaturated
    static let spendyAccentLight = Color(hex: "8B5CF6")   // Violet 500 — softer tint
    static let spendyAccentDeep = Color(hex: "5B21B6")    // Violet 800 — deep anchor

    // MARK: - Background Colors
    // Warm tinted surfaces instead of cold slate
    static let spendyBackground = Color(hex: "F5F4F7")        // Warm off-white with violet tint
    static let spendyBackgroundDark = Color(hex: "EAE8F0")    // Slightly deeper warm surface
    static let spendyBackgroundDeep = Color(hex: "DDDBE8")    // For pressed/active states

    // MARK: - Surface Colors
    // Warm white surfaces (slight warmth vs pure white)
    static let spendySurface = Color(hex: "FEFEFE")           // Near-white, warm
    static let spendySurfaceElevated = Color(hex: "FAFAFC")   // Slightly elevated, hint of violet
    static let spendySurfaceOverlay = Color(hex: "F7F6FA")    // Used for sheet overlays

    // MARK: - Text Colors
    static let spendyText = Color(hex: "1A1730")              // Deep blue-black (warmer than slate 900)
    static let spendySecondaryText = Color(hex: "6B6A80")     // Muted violet-grey
    static let spendyTertiaryText = Color(hex: "9896A8")      // Very muted, for hints/placeholders

    // MARK: - Semantic Colors (Slightly desaturated for elegance)
    static let spendyRed = Color(hex: "E04545")               // Softened red
    static let spendyRedLight = Color(hex: "FEE2E2")          // Red tint for backgrounds
    static let spendyGreen = Color(hex: "0DA678")             // Emerald, slightly desaturated
    static let spendyGreenLight = Color(hex: "D1FAE5")        // Green tint for backgrounds
    static let spendyBlue = Color(hex: "3A7BD5")              // Desaturated blue
    static let spendyBlueLight = Color(hex: "DBEAFE")         // Blue tint for backgrounds
    static let spendyOrange = Color(hex: "E89020")            // Amber, desaturated
    static let spendyOrangeLight = Color(hex: "FEF3C7")       // Orange tint for backgrounds
    static let spendyPink = Color(hex: "D6498A")              // Desaturated pink
    static let spendyPinkLight = Color(hex: "FCE7F3")         // Pink tint for backgrounds
    static let spendyCyan = Color(hex: "0898AA")              // Desaturated cyan
    static let spendyCyanLight = Color(hex: "CFFAFE")         // Cyan tint for backgrounds

    // MARK: - Multi-layer Shadow Colors
    // Named shadows for consistent depth system
    static let spendyShadowPrimary = Color(hex: "4F46E5").opacity(0.18)  // Brand-colored glow
    static let spendyShadowNear = Color(hex: "1A1730").opacity(0.06)     // Close, sharp shadow
    static let spendyShadowFar = Color(hex: "1A1730").opacity(0.03)      // Distant, diffuse shadow
    static let spendyShadowCard = Color(hex: "2D2B5A").opacity(0.08)     // Card-specific shadow
    static let spendyShadowElevated = Color(hex: "1A1730").opacity(0.12) // Elevated element shadow

    // MARK: - Gradient Border Colors
    static let spendyBorderSubtle = Color(hex: "E8E6F0")      // Very light violet border
    static let spendyBorderMedium = Color(hex: "C8C5D8")      // Medium violet-grey border

    // MARK: - Gradient Definitions

    /// Main brand gradient — deeper indigo to rich violet
    static var spendyGradient: LinearGradient {
        LinearGradient(
            colors: [spendyPrimary, spendyAccent],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// Deeper, card-header gradient with dark anchor
    static var spendyGradientDeep: LinearGradient {
        LinearGradient(
            colors: [spendyPrimaryDark, spendyAccent, spendyAccentDeep],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// Subtle tinted background gradient (for section fills)
    static var spendyGradientSubtle: LinearGradient {
        LinearGradient(
            colors: [spendyPrimary.opacity(0.08), spendyAccent.opacity(0.04)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// Warm background gradient (for full-screen backgrounds)
    static var spendyGradientBackground: LinearGradient {
        LinearGradient(
            colors: [spendyBackground, spendyBackgroundDark],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    /// Gradient border (use with overlay + mask)
    static var spendyGradientBorder: LinearGradient {
        LinearGradient(
            colors: [spendyPrimaryLight.opacity(0.6), spendyAccentLight.opacity(0.3)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // MARK: - Mesh Gradient

    @MainActor
    static var spendyMeshGradient: some View {
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0, 0], [0.5, 0], [1, 0],
                [0, 0.5], [0.5, 0.5], [1, 0.5],
                [0, 1], [0.5, 1], [1, 1]
            ],
            colors: [
                spendyPrimary.opacity(0.28),   spendyAccent.opacity(0.18),    spendyCyan.opacity(0.08),
                spendyAccent.opacity(0.20),    spendyPrimary.opacity(0.12),   spendyPink.opacity(0.08),
                spendyCyan.opacity(0.08),      spendyPrimaryLight.opacity(0.16), spendyAccent.opacity(0.24)
            ]
        )
    }

    // MARK: - Hex Initializer

    /// Creates a Color from a 3, 6, or 8 character hex string.
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 255, 255, 255)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
