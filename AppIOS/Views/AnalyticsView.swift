import Charts
import SwiftUI

// MARK: - AnalyticsView

struct AnalyticsView: View {
    @StateObject private var viewModel = AnalyticsViewModel()

    @State private var selectedYear = "2025"
    @State private var selectedFilter = "Tutte le spese"
    @State private var selectedMonth: String? = nil

    // Animation state for category progress bars
    @State private var progressAnimated = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.spendyBackground
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 24) {
                        if viewModel.isLoading {
                            loadingView
                        } else if let error = viewModel.errorMessage {
                            errorView(error)
                        } else {
                            filterSection

                            summaryCardsSection

                            chartSection

                            categoriesSection
                        }
                    }
                    .padding(.vertical, 20)
                    .padding(.bottom, 100)
                }
            }
            .navigationTitle("Analytics")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Color.spendyBackground, for: .navigationBar)
            .onAppear {
                viewModel.loadData()
                viewModel.fetchMonthlyStats(year: selectedYear)
            }
            .refreshable {
                viewModel.loadData()
            }
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 24) {
            // Summary cards skeleton
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(0..<3) { _ in
                        SkeletonSummaryCard()
                    }
                }
                .padding(.horizontal, 20)
            }

            // Chart skeleton
            SpendyCard(style: .elevated, padding: 20) {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        SkeletonElement(shape: .roundedRectangle(radius: 6), width: 180, height: 18)
                        SkeletonElement(shape: .roundedRectangle(radius: 5), width: 240, height: 13)
                    }
                    SkeletonElement(shape: .roundedRectangle(radius: 12), width: nil, height: 200)
                }
            }
            .padding(.horizontal, 20)

            // Categories skeleton
            SpendyCard(style: .default, padding: 0) {
                VStack(spacing: 0) {
                    ForEach(0..<4) { index in
                        HStack(spacing: 14) {
                            SkeletonElement(shape: .circle, width: 44, height: 44)
                            VStack(alignment: .leading, spacing: 8) {
                                SkeletonElement(shape: .roundedRectangle(radius: 6), width: 120, height: 13)
                                SkeletonElement(shape: .roundedRectangle(radius: 5), width: 80, height: 10)
                            }
                            Spacer()
                            SkeletonElement(shape: .roundedRectangle(radius: 8), width: 72, height: 18)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 16)

                        if index < 3 {
                            Divider()
                                .padding(.leading, 74)
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.top, 8)
    }

    // MARK: - Error View

    private func errorView(_ message: String) -> some View {
        SpendyCard(style: .default, padding: 16) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Color.spendyOrangeLight)
                        .frame(width: 40, height: 40)
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.spendyOrange)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Errore nel caricamento")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.spendyText)

                    Text(message)
                        .font(.caption)
                        .foregroundColor(.spendySecondaryText)
                        .lineLimit(2)
                }

                Spacer()
            }
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Filter Section

    private var filterSection: some View {
        VStack(spacing: 16) {
            // Year and filter dropdowns row
            HStack(spacing: 12) {
                FilterDropdown(
                    label: "Anno",
                    value: selectedYear,
                    icon: "calendar"
                ) {
                    ForEach(Array(2020...2030), id: \.self) { year in
                        Button(String(year)) {
                            selectedYear = String(year)
                            viewModel.updateFilters(year: selectedYear)
                        }
                    }
                }

                FilterDropdown(
                    label: "Filtro",
                    value: selectedFilter,
                    icon: "line.3.horizontal.decrease"
                ) {
                    Button("Tutte le spese") {
                        viewModel.filterMode = .all
                        selectedFilter = "Tutte le spese"
                    }
                    Button("Per Mese") {
                        viewModel.filterMode = .month
                        selectedFilter = "Per Mese"
                    }
                    Button("Per Data") {
                        viewModel.filterMode = .dateRange
                        selectedFilter = "Per Data"
                    }
                }
            }

            // Contextual filter picker
            if viewModel.filterMode == .month {
                SpendyCard(style: .gradientBordered, padding: 16) {
                    HStack(spacing: 12) {
                        // Mese picker
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Mese")
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundColor(.spendySecondaryText)
                                .textCase(.uppercase)
                                .tracking(0.5)

                            Picker("Mese", selection: $viewModel.selectedMonth) {
                                ForEach(1...12, id: \.self) { month in
                                    Text(Calendar.current.monthSymbols[month - 1]).tag(month)
                                }
                            }
                            .pickerStyle(.menu)
                            .tint(.spendyPrimary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        Rectangle()
                            .fill(Color.spendyBorderSubtle)
                            .frame(width: 1, height: 44)

                        // Anno picker
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Anno")
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundColor(.spendySecondaryText)
                                .textCase(.uppercase)
                                .tracking(0.5)

                            Picker("Anno", selection: $viewModel.selectedYearInt) {
                                ForEach(Array(2020...2030), id: \.self) { year in
                                    Text(String(year)).tag(year)
                                }
                            }
                            .pickerStyle(.menu)
                            .tint(.spendyPrimary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            } else if viewModel.filterMode == .dateRange {
                SpendyCard(style: .gradientBordered, padding: 16) {
                    VStack(spacing: 16) {
                        HStack {
                            Image(systemName: "calendar.badge.plus")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.spendyPrimary)
                            Text("Intervallo date")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.spendySecondaryText)
                                .textCase(.uppercase)
                                .tracking(0.5)
                            Spacer()
                        }

                        VStack(spacing: 12) {
                            HStack {
                                Text("Da")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.spendyText)
                                    .frame(width: 28, alignment: .leading)

                                DatePicker(
                                    "Da", selection: $viewModel.selectedDateRange.start,
                                    displayedComponents: .date)
                                    .labelsHidden()
                                    .tint(.spendyPrimary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }

                            Divider()

                            HStack {
                                Text("A")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.spendyText)
                                    .frame(width: 28, alignment: .leading)

                                DatePicker(
                                    "A", selection: $viewModel.selectedDateRange.end,
                                    displayedComponents: .date)
                                    .labelsHidden()
                                    .tint(.spendyPrimary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    }
                }
            }

            // Apply filters button
            SpendyButton(
                "Applica filtri",
                leadingIcon: "checkmark.circle.fill",
                action: {
                    viewModel.applyFilters()
                }
            )
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Summary Cards Section

    private var summaryCardsSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ModernSummaryCard(
                    title: "Uscite Totali",
                    value: viewModel.totalBalance,
                    subtitle: "\(viewModel.totalTransactions) movimenti",
                    icon: "arrow.down.circle.fill",
                    gradient: [Color.spendyRed, Color.spendyPink]
                )

                ModernSummaryCard(
                    title: "Spesa Media",
                    value: viewModel.averageExpense,
                    subtitle: "Per transazione",
                    icon: "chart.bar.fill",
                    gradient: [Color.spendyBlue, Color.spendyCyan]
                )

                ModernSummaryCard(
                    title: "Uscita Maggiore",
                    value: viewModel.highestExpense,
                    subtitle: "Movimento più alto",
                    icon: "flame.fill",
                    gradient: [Color.spendyOrange, Color.spendyRed]
                )
            }
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Chart Section

    private var chartSection: some View {
        SpendyCard(style: .elevated, padding: 20) {
            VStack(alignment: .leading, spacing: 20) {

                // Section header
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Andamento Mensile")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.spendyText)

                        Text("Spese registrate nel corso dell'anno")
                            .font(.subheadline)
                            .foregroundColor(.spendySecondaryText)
                    }
                    Spacer()

                    // Gradient chart legend dot
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color.spendyGradient)
                            .frame(width: 8, height: 8)
                        Text("Uscite")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.spendySecondaryText)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.spendyBackgroundDark)
                    .clipShape(Capsule())
                }

                // Chart
                Chart {
                    ForEach(viewModel.monthlyData) { item in
                        LineMark(
                            x: .value("Data", item.month),
                            y: .value("Importo", item.amount)
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.spendyPrimary, .spendyAccent],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round))

                        AreaMark(
                            x: .value("Data", item.month),
                            y: .value("Importo", item.amount)
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    .spendyPrimary.opacity(0.22),
                                    .spendyAccentLight.opacity(0.10),
                                    .spendyAccent.opacity(0.02)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                        PointMark(
                            x: .value("Data", item.month),
                            y: .value("Importo", item.amount)
                        )
                        .foregroundStyle(Color.spendyPrimary)
                        .symbolSize(18)
                    }

                    if let selectedMonth,
                        let item = viewModel.monthlyData.first(where: { $0.month == selectedMonth })
                    {
                        RuleMark(x: .value("Data", selectedMonth))
                            .foregroundStyle(Color.spendyPrimary.opacity(0.45))
                            .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
                            .annotation(position: .top, alignment: .center, spacing: 8) {
                                VStack(spacing: 5) {
                                    Text(item.month)
                                        .font(.caption2)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.spendySecondaryText)
                                        .textCase(.uppercase)
                                        .tracking(0.5)

                                    Text(item.amount, format: .currency(code: "EUR"))
                                        .font(.subheadline)
                                        .fontWeight(.bold)
                                        .foregroundStyle(Color.spendyGradient)
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(.ultraThinMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(Color.spendyGradientBorder, lineWidth: 1)
                                )
                                .shadow(color: Color.spendyShadowCard, radius: 10, x: 0, y: 4)
                            }
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { _ in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4, 4]))
                            .foregroundStyle(Color.spendyBorderSubtle)
                        AxisValueLabel()
                            .foregroundStyle(Color.spendyTertiaryText)
                            .font(.caption2)
                    }
                }
                .chartXAxis {
                    AxisMarks { _ in
                        AxisValueLabel()
                            .foregroundStyle(Color.spendySecondaryText)
                            .font(.caption2)
                    }
                }
                .frame(height: 230)
                .chartOverlay { proxy in
                    GeometryReader { _ in
                        Rectangle().fill(.clear).contentShape(Rectangle())
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        if let month: String = proxy.value(atX: value.location.x) {
                                            selectedMonth = month
                                        }
                                    }
                                    .onEnded { _ in
                                        selectedMonth = nil
                                    }
                            )
                    }
                }
            }
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Categories Section

    private var categoriesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section header (outside card)
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Top Categorie")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.spendyText)

                    Text("Spese per categoria")
                        .font(.caption)
                        .foregroundColor(.spendySecondaryText)
                }
                Spacer()
            }
            .padding(.horizontal, 20)

            // Category rows card
            SpendyCard(style: .default, padding: 0) {
                VStack(spacing: 0) {
                    ForEach(Array(viewModel.topCategories.enumerated()), id: \.element.id) {
                        index, category in
                        CategoryRow(
                            category: category,
                            index: index + 1,
                            maxAmount: viewModel.topCategories.first?.amount ?? 1,
                            progressAnimated: progressAnimated
                        )

                        if index < viewModel.topCategories.count - 1 {
                            Divider()
                                .padding(.leading, 74)
                                .padding(.trailing, 16)
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .onAppear {
                withAnimation(.easeOut(duration: 0.9).delay(0.3)) {
                    progressAnimated = true
                }
            }
        }
    }
}

// MARK: - FilterDropdown

struct FilterDropdown<Content: View>: View {
    let label: String
    let value: String
    let icon: String
    @ViewBuilder let content: Content

    var body: some View {
        Menu {
            content
        } label: {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Color.spendyPrimary.opacity(0.1))
                        .frame(width: 32, height: 32)
                    Image(systemName: icon)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.spendyPrimary)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(.spendyTertiaryText)
                        .textCase(.uppercase)
                        .tracking(0.4)

                    Text(value)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.spendyText)
                        .lineLimit(1)
                }

                Spacer()

                Image(systemName: "chevron.down")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.spendySecondaryText)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color.spendySurface)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.spendyBorderSubtle, lineWidth: 1)
            )
            .shadow(color: Color.spendyShadowNear, radius: 6, x: 0, y: 2)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - ModernSummaryCard

struct ModernSummaryCard: View {
    let title: String
    let value: Double
    let subtitle: String
    let icon: String
    let gradient: [Color]

    var body: some View {
        SpendyCard(style: .gradientBordered, padding: 20) {
            VStack(alignment: .leading, spacing: 16) {
                // Icon badge
                HStack {
                    ZStack {
                        Circle()
                            .fill(gradient[0].opacity(0.12))
                            .frame(width: 44, height: 44)

                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: gradient,
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                                .opacity(0.18)
                            )
                            .frame(width: 44, height: 44)

                        Image(systemName: icon)
                            .font(.system(size: 19, weight: .semibold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: gradient,
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    Spacer()
                }

                // Text stack
                VStack(alignment: .leading, spacing: 5) {
                    Text(subtitle)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.spendyTertiaryText)
                        .textCase(.uppercase)
                        .tracking(0.4)

                    Text(value, format: .currency(code: "EUR"))
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(.spendyText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)

                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.spendySecondaryText)
                }
            }
        }
        .frame(width: 200)
        .shadow(color: gradient[0].opacity(0.12), radius: 16, x: 0, y: 6)
    }
}

// MARK: - CategoryRow

struct CategoryRow: View {
    let category: AnalyticsViewModel.CategoryMetric
    let index: Int
    let maxAmount: Double
    let progressAnimated: Bool

    var categoryColor: Color {
        CategoryMapper.color(for: category.name)
    }

    var categoryIcon: String {
        CategoryMapper.icon(for: category.name)
    }

    private var progressFraction: CGFloat {
        guard maxAmount > 0 else { return 0 }
        return CGFloat(min(category.amount / maxAmount, 1.0))
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                // Rank badge
                ZStack {
                    Circle()
                        .fill(rankGradient)
                        .frame(width: 22, height: 22)

                    Text("\(index)")
                        .font(.system(size: 11, weight: .black))
                        .foregroundColor(.white)
                }

                // Category icon badge
                ZStack {
                    Circle()
                        .fill(categoryColor.opacity(0.12))
                        .frame(width: 44, height: 44)

                    Image(systemName: categoryIcon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(categoryColor)
                }

                // Text info
                VStack(alignment: .leading, spacing: 3) {
                    Text(category.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.spendyText)
                        .lineLimit(1)

                    Text("\(category.count) movimenti")
                        .font(.caption)
                        .foregroundColor(.spendySecondaryText)
                }

                Spacer()

                // Amount
                Text(category.amount, format: .currency(code: "EUR"))
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(.spendyText)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Track
                    Capsule()
                        .fill(Color.spendyBackgroundDark)
                        .frame(height: 5)

                    // Fill
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [categoryColor, categoryColor.opacity(0.6)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(
                            width: progressAnimated
                                ? geo.size.width * progressFraction
                                : 0,
                            height: 5
                        )
                }
            }
            .frame(height: 5)
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, 16)
        }
    }

    private var rankGradient: LinearGradient {
        switch index {
        case 1:
            return LinearGradient(
                colors: [Color(hex: "F5A623"), Color(hex: "E07B00")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case 2:
            return LinearGradient(
                colors: [Color(hex: "B0B8C4"), Color(hex: "8A9199")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case 3:
            return LinearGradient(
                colors: [Color(hex: "CD7F32"), Color(hex: "9E5E1E")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        default:
            return LinearGradient(
                colors: [Color.spendyPrimary.opacity(0.5), Color.spendyAccent.opacity(0.4)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}
