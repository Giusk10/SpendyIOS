import Charts
import SwiftUI

struct AnalyticsView: View {
    @StateObject private var viewModel = AnalyticsViewModel()

    @State private var selectedYear = "2025"
    @State private var selectedFilter = "Tutte le spese"
    @State private var selectedMonth: String? = nil

    var body: some View {
        NavigationView {
            ZStack {
                Color.spendyBackground
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
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
                    .padding(.bottom, 60)
                }
            }
            .navigationTitle("Analytics")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                viewModel.loadData()
                viewModel.fetchMonthlyStats(year: selectedYear)
            }
            .refreshable {
                viewModel.loadData()
            }
        }
    }

    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Caricamento dati...")
                .font(.subheadline)
                .foregroundColor(.spendySecondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    private func errorView(_ message: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.spendyOrange)
            Text(message)
                .font(.subheadline)
                .foregroundColor(.spendyText)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.spendyOrange.opacity(0.1))
        .cornerRadius(16)
        .padding(.horizontal, 20)
    }

    private var filterSection: some View {
        VStack(spacing: 16) {
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

            if viewModel.filterMode == .month {
                HStack(spacing: 12) {
                    Picker("Mese", selection: $viewModel.selectedMonth) {
                        ForEach(1...12, id: \.self) { month in
                            Text(Calendar.current.monthSymbols[month - 1]).tag(month)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(.spendyPrimary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)

                    Picker("Anno", selection: $viewModel.selectedYearInt) {
                        ForEach(Array(2020...2030), id: \.self) { year in
                            Text(String(year)).tag(year)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(.spendyPrimary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
                }
            } else if viewModel.filterMode == .dateRange {
                VStack(spacing: 12) {
                    DatePicker(
                        "Da", selection: $viewModel.selectedDateRange.start,
                        displayedComponents: .date)
                    DatePicker(
                        "A", selection: $viewModel.selectedDateRange.end, displayedComponents: .date
                    )
                }
                .padding(16)
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
            }

            Button(action: {
                viewModel.applyFilters()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Applica filtri")
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.spendyGradient)
                .cornerRadius(14)
                .shadow(color: Color.spendyPrimary.opacity(0.3), radius: 8, x: 0, y: 4)
            }
        }
        .padding(.horizontal, 20)
    }

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

    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Andamento Mensile")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.spendyText)

                Text("Spese registrate nel corso dell'anno")
                    .font(.subheadline)
                    .foregroundColor(.spendySecondaryText)
            }
            .padding(.horizontal, 20)

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
                    .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))

                    AreaMark(
                        x: .value("Data", item.month),
                        y: .value("Importo", item.amount)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.spendyPrimary.opacity(0.25), .spendyAccent.opacity(0.05)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }

                if let selectedMonth,
                    let item = viewModel.monthlyData.first(where: { $0.month == selectedMonth })
                {
                    RuleMark(x: .value("Data", selectedMonth))
                        .foregroundStyle(Color.spendyPrimary.opacity(0.5))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                        .annotation(position: .top, alignment: .center) {
                            VStack(spacing: 4) {
                                Text(item.month)
                                    .font(.caption)
                                    .foregroundColor(.spendySecondaryText)
                                Text(item.amount, format: .currency(code: "EUR"))
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .foregroundStyle(Color.spendyGradient)
                            }
                            .padding(12)
                            .background(.ultraThinMaterial)
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                        }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4, 4]))
                        .foregroundStyle(Color.spendySecondaryText.opacity(0.2))
                    AxisValueLabel()
                        .foregroundStyle(Color.spendySecondaryText)
                }
            }
            .chartXAxis {
                AxisMarks { _ in
                    AxisValueLabel()
                        .foregroundStyle(Color.spendySecondaryText)
                }
            }
            .frame(height: 250)
            .padding(.horizontal, 20)
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
        .padding(.vertical, 20)
        .background(Color.white)
        .cornerRadius(24)
        .shadow(color: Color.black.opacity(0.06), radius: 16, x: 0, y: 6)
        .padding(.horizontal, 20)
    }

    private var categoriesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Top Categorie")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.spendyText)
                .padding(.horizontal, 20)

            VStack(spacing: 0) {
                ForEach(Array(viewModel.topCategories.enumerated()), id: \.element.id) {
                    index, category in
                    CategoryRow(category: category, index: index + 1)

                    if index < viewModel.topCategories.count - 1 {
                        Divider()
                            .padding(.leading, 56)
                    }
                }
            }
            .background(Color.white)
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
            .padding(.horizontal, 20)
        }
    }
}

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
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(.spendyPrimary)

                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .font(.caption2)
                        .foregroundColor(.spendySecondaryText)
                    Text(value)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.spendyText)
                }

                Spacer()

                Image(systemName: "chevron.down")
                    .font(.caption)
                    .foregroundColor(.spendySecondaryText)
            }
            .padding(14)
            .background(Color.white)
            .cornerRadius(14)
            .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
        }
    }
}

struct ModernSummaryCard: View {
    let title: String
    let value: Double
    let subtitle: String
    let icon: String
    let gradient: [Color]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 40, height: 40)

                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                }

                Spacer()
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(value, format: .currency(code: "EUR"))
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white.opacity(0.9))

                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .frame(width: 200)
        .padding(20)
        .background(
            LinearGradient(colors: gradient, startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .cornerRadius(20)
        .shadow(color: gradient[0].opacity(0.4), radius: 12, x: 0, y: 6)
    }
}

struct CategoryRow: View {
    let category: AnalyticsViewModel.CategoryMetric
    let index: Int

    var categoryColor: Color {
        CategoryMapper.color(for: category.name)
    }

    var categoryIcon: String {
        CategoryMapper.icon(for: category.name)
    }

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(categoryColor.opacity(0.15))
                    .frame(width: 42, height: 42)

                Image(systemName: categoryIcon)
                    .font(.system(size: 18))
                    .foregroundColor(categoryColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(category.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.spendyText)

                Text("\(category.count) movimenti")
                    .font(.caption)
                    .foregroundColor(.spendySecondaryText)
            }

            Spacer()

            Text(category.amount, format: .currency(code: "EUR"))
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(.spendyText)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}
