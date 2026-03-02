import SwiftUI

// MARK: - Gradient Orb Configuration

/// Defines the visual properties and animation parameters for a single gradient orb.
struct GradientOrb: Identifiable {
    let id: UUID
    let color: Color
    let size: CGFloat
    let blurRadius: CGFloat
    let initialOffset: CGSize
    let amplitude: CGSize    // Max drift range during animation

    init(
        color: Color,
        size: CGFloat,
        blurRadius: CGFloat,
        initialOffset: CGSize,
        amplitude: CGSize
    ) {
        self.id = UUID()
        self.color = color
        self.size = size
        self.blurRadius = blurRadius
        self.initialOffset = initialOffset
        self.amplitude = amplitude
    }
}

// MARK: - AnimatedGradientBackground

/// A reusable animated gradient background built from drifting blurred orbs.
///
/// The component composes several soft color orbs that animate slowly to create
/// a living, breathing ambient gradient effect. Colors are fully configurable.
/// Designed to run continuously on screen without excessive CPU/GPU cost.
///
/// Usage:
/// ```swift
/// ZStack {
///     AnimatedGradientBackground()   // Default brand palette
///     YourContent()
/// }
///
/// // Custom colors
/// AnimatedGradientBackground(
///     orbs: [
///         GradientOrb(color: .blue.opacity(0.3), size: 280, blurRadius: 70,
///                     initialOffset: CGSize(width: -80, height: -200),
///                     amplitude: CGSize(width: 60, height: 80)),
///     ]
/// )
/// ```
struct AnimatedGradientBackground: View {

    let orbs: [GradientOrb]
    let baseColor: Color
    let animationDuration: Double

    // Per-orb animated offsets driven by a phase value [0, 1]
    @State private var phase: Double = 0

    // MARK: - Initializers

    /// Creates the background with the default Spendy brand palette.
    init(animationDuration: Double = 12) {
        self.animationDuration = animationDuration
        self.baseColor = Color.spendyBackground
        self.orbs = Self.defaultOrbs
    }

    /// Creates the background with a custom set of orbs.
    init(
        orbs: [GradientOrb],
        baseColor: Color = Color.spendyBackground,
        animationDuration: Double = 12
    ) {
        self.orbs = orbs
        self.baseColor = baseColor
        self.animationDuration = animationDuration
    }

    // MARK: - Default Orbs

    private static var defaultOrbs: [GradientOrb] {
        [
            GradientOrb(
                color: Color.spendyPrimary.opacity(0.22),
                size: 320,
                blurRadius: 80,
                initialOffset: CGSize(width: -120, height: -280),
                amplitude: CGSize(width: 70, height: 60)
            ),
            GradientOrb(
                color: Color.spendyAccent.opacity(0.18),
                size: 260,
                blurRadius: 70,
                initialOffset: CGSize(width: 140, height: 320),
                amplitude: CGSize(width: -50, height: -90)
            ),
            GradientOrb(
                color: Color.spendyCyan.opacity(0.10),
                size: 200,
                blurRadius: 60,
                initialOffset: CGSize(width: 100, height: -180),
                amplitude: CGSize(width: -80, height: 50)
            ),
            GradientOrb(
                color: Color.spendyPink.opacity(0.08),
                size: 180,
                blurRadius: 55,
                initialOffset: CGSize(width: -80, height: 220),
                amplitude: CGSize(width: 60, height: -70)
            )
        ]
    }

    // MARK: - Body

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                baseColor

                ForEach(Array(orbs.enumerated()), id: \.element.id) { index, orb in
                    animatedOrb(orb: orb, index: index, containerSize: geometry.size)
                }
            }
        }
        .ignoresSafeArea()
        .onAppear { startAnimation() }
    }

    // MARK: - Orb Construction

    private func animatedOrb(orb: GradientOrb, index: Int, containerSize: CGSize) -> some View {
        // Phase offset per orb so they drift independently and don't lock together
        let orbPhase = (phase + Double(index) * 0.25).truncatingRemainder(dividingBy: 1.0)
        let angle = orbPhase * 2 * .pi
        let driftX = orb.amplitude.width * sin(angle)
        let driftY = orb.amplitude.height * cos(angle + Double(index))

        return Circle()
            .fill(orb.color)
            .frame(width: orb.size, height: orb.size)
            .blur(radius: orb.blurRadius)
            .offset(
                x: orb.initialOffset.width + driftX,
                y: orb.initialOffset.height + driftY
            )
            .allowsHitTesting(false)
    }

    // MARK: - Animation Control

    private func startAnimation() {
        withAnimation(
            .linear(duration: animationDuration)
            .repeatForever(autoreverses: false)
        ) {
            phase = 1.0
        }
    }
}

// MARK: - Preview

#Preview("AnimatedGradientBackground") {
    ZStack {
        AnimatedGradientBackground()

        VStack(spacing: 16) {
            Text("Spendy")
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundStyle(Color.spendyGradient)

            Text("Animated gradient background")
                .font(.subheadline)
                .foregroundColor(.spendySecondaryText)
        }
    }
}

#Preview("Custom Orbs") {
    ZStack {
        AnimatedGradientBackground(
            orbs: [
                GradientOrb(
                    color: Color.spendyGreen.opacity(0.25),
                    size: 300,
                    blurRadius: 90,
                    initialOffset: CGSize(width: -100, height: -250),
                    amplitude: CGSize(width: 60, height: 80)
                ),
                GradientOrb(
                    color: Color.spendyCyan.opacity(0.18),
                    size: 240,
                    blurRadius: 70,
                    initialOffset: CGSize(width: 130, height: 300),
                    amplitude: CGSize(width: -50, height: -70)
                )
            ],
            baseColor: Color(hex: "F0FAF9"),
            animationDuration: 16
        )

        Text("Custom Palette")
            .font(.title2.bold())
            .foregroundColor(.spendyText)
    }
}
