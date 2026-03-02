import SwiftUI

// MARK: - Skeleton Shape

/// Defines the outline shape of a skeleton placeholder element.
enum SkeletonShape {
    case rectangle
    case circle
    case roundedRectangle(radius: CGFloat)
    case capsule
}

// MARK: - SkeletonElement

/// A single shimmer/skeleton loading placeholder element.
///
/// The shimmer gradient animates from leading to trailing to simulate
/// a moving light reflection over a loading surface.
///
/// Usage:
/// ```swift
/// SkeletonElement(shape: .roundedRectangle(radius: 12), width: .infinity, height: 20)
/// SkeletonElement(shape: .circle, width: 44, height: 44)
/// SkeletonElement(shape: .capsule, width: 80, height: 16)
/// ```
struct SkeletonElement: View {

    let shape: SkeletonShape
    let width: CGFloat?        // nil means maxWidth: .infinity
    let height: CGFloat

    @State private var shimmerOffset: CGFloat = -1

    // Shimmer gradient colors built from the brand surface palette
    private let baseColor = Color.spendyBackgroundDark
    private let highlightColor = Color.spendySurface.opacity(0.9)

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                baseColor

                LinearGradient(
                    stops: [
                        .init(color: .clear, location: 0),
                        .init(color: highlightColor, location: 0.4),
                        .init(color: highlightColor, location: 0.6),
                        .init(color: .clear, location: 1)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: geometry.size.width * 2)
                .offset(x: shimmerOffset * geometry.size.width)
            }
            .clipShape(resolvedShape)
        }
        .frame(width: width, height: height)
        .onAppear { startShimmer() }
    }

    // MARK: - Shape Resolution

    private var resolvedShape: AnyShape {
        switch shape {
        case .rectangle:
            AnyShape(Rectangle())
        case .circle:
            AnyShape(Circle())
        case .roundedRectangle(let radius):
            AnyShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
        case .capsule:
            AnyShape(Capsule())
        }
    }

    // MARK: - Animation

    private func startShimmer() {
        shimmerOffset = -1.5
        withAnimation(
            .linear(duration: 1.4)
            .repeatForever(autoreverses: false)
        ) {
            shimmerOffset = 1.5
        }
    }
}

// MARK: - AnyShape Helper

/// Type-erased Shape wrapper required for branching on shapes in a single return type.
private struct AnyShape: Shape, @unchecked Sendable {
    private let pathBuilder: @Sendable (CGRect) -> Path

    init<S: Shape>(_ shape: S) {
        pathBuilder = { rect in shape.path(in: rect) }
    }

    func path(in rect: CGRect) -> Path {
        pathBuilder(rect)
    }
}

// MARK: - Pre-built Skeleton Layouts

/// A skeleton layout mimicking a transaction row (icon + two text lines + amount chip).
struct SkeletonTransactionRow: View {
    var body: some View {
        HStack(spacing: 14) {
            SkeletonElement(shape: .circle, width: 44, height: 44)

            VStack(alignment: .leading, spacing: 8) {
                SkeletonElement(shape: .roundedRectangle(radius: 6), width: 140, height: 13)
                SkeletonElement(shape: .roundedRectangle(radius: 5), width: 90, height: 10)
            }

            Spacer()

            SkeletonElement(shape: .roundedRectangle(radius: 8), width: 64, height: 18)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

/// A skeleton layout mimicking a summary analytics card (icon + value + label).
struct SkeletonSummaryCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SkeletonElement(shape: .circle, width: 40, height: 40)

            VStack(alignment: .leading, spacing: 8) {
                SkeletonElement(shape: .roundedRectangle(radius: 6), width: 100, height: 22)
                SkeletonElement(shape: .roundedRectangle(radius: 5), width: 130, height: 13)
                SkeletonElement(shape: .roundedRectangle(radius: 4), width: 80, height: 10)
            }
        }
        .frame(width: 200)
        .padding(20)
        .background(Color.spendySurface)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color.spendyShadowNear, radius: 8, x: 0, y: 3)
    }
}

/// A skeleton layout mimicking the main balance card header.
struct SkeletonBalanceCard: View {
    var body: some View {
        VStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color.spendyBackgroundDark)
                .overlay {
                    VStack(alignment: .leading, spacing: 20) {
                        HStack {
                            VStack(alignment: .leading, spacing: 10) {
                                SkeletonElement(shape: .roundedRectangle(radius: 5), width: 90, height: 13)
                                SkeletonElement(shape: .roundedRectangle(radius: 8), width: 160, height: 32)
                            }
                            Spacer()
                            SkeletonElement(shape: .circle, width: 44, height: 44)
                        }

                        HStack(spacing: 0) {
                            HStack(spacing: 10) {
                                SkeletonElement(shape: .circle, width: 32, height: 32)
                                VStack(alignment: .leading, spacing: 6) {
                                    SkeletonElement(shape: .roundedRectangle(radius: 4), width: 50, height: 9)
                                    SkeletonElement(shape: .roundedRectangle(radius: 5), width: 75, height: 14)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)

                            SkeletonElement(shape: .roundedRectangle(radius: 3), width: 1, height: 30)
                                .padding(.horizontal, 16)

                            HStack(spacing: 10) {
                                SkeletonElement(shape: .circle, width: 32, height: 32)
                                VStack(alignment: .leading, spacing: 6) {
                                    SkeletonElement(shape: .roundedRectangle(radius: 4), width: 50, height: 9)
                                    SkeletonElement(shape: .roundedRectangle(radius: 5), width: 75, height: 14)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding(24)
                }
                .frame(height: 200)
        }
    }
}

/// A full-page skeleton layout for the dashboard loading state.
struct SkeletonDashboard: View {
    var body: some View {
        LazyVStack(spacing: 24) {
            SkeletonBalanceCard()

            // Filter chips
            HStack(spacing: 12) {
                ForEach(0..<3) { _ in
                    SkeletonElement(shape: .capsule, width: 80, height: 36)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Transactions section header
            HStack {
                SkeletonElement(shape: .roundedRectangle(radius: 6), width: 170, height: 18)
                Spacer()
                SkeletonElement(shape: .roundedRectangle(radius: 5), width: 70, height: 14)
            }

            // Transaction rows
            VStack(spacing: 0) {
                ForEach(0..<4) { index in
                    SkeletonTransactionRow()
                    if index < 3 {
                        Divider().padding(.leading, 74)
                    }
                }
            }
            .background(Color.spendySurface)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: Color.spendyShadowCard, radius: 10, x: 0, y: 4)
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }
}

// MARK: - Preview

#Preview("Skeleton Elements") {
    ScrollView {
        VStack(alignment: .leading, spacing: 24) {
            Text("Single Elements")
                .font(.caption.bold())
                .foregroundColor(.spendySecondaryText)

            HStack(spacing: 12) {
                SkeletonElement(shape: .circle, width: 44, height: 44)
                SkeletonElement(shape: .circle, width: 60, height: 60)
                SkeletonElement(shape: .circle, width: 80, height: 80)
            }

            VStack(alignment: .leading, spacing: 8) {
                SkeletonElement(shape: .roundedRectangle(radius: 6), width: nil, height: 16)
                SkeletonElement(shape: .roundedRectangle(radius: 6), width: 240, height: 12)
                SkeletonElement(shape: .roundedRectangle(radius: 6), width: 180, height: 12)
            }

            HStack(spacing: 8) {
                SkeletonElement(shape: .capsule, width: 80, height: 32)
                SkeletonElement(shape: .capsule, width: 96, height: 32)
                SkeletonElement(shape: .capsule, width: 70, height: 32)
            }

            Divider()

            Text("Composite Layouts")
                .font(.caption.bold())
                .foregroundColor(.spendySecondaryText)

            SkeletonTransactionRow()
                .background(Color.spendySurface)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(0..<3) { _ in
                        SkeletonSummaryCard()
                    }
                }
                .padding(.horizontal, 1)
            }

            Divider()

            Text("Dashboard Skeleton")
                .font(.caption.bold())
                .foregroundColor(.spendySecondaryText)

            SkeletonDashboard()
        }
        .padding(20)
    }
    .background(Color.spendyBackground)
}
