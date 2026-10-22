import Charts
import SwiftUI

struct AnalyticsView: View {
    @State private var viewModel = AnalyticsViewModel()
    @ObservedObject private var service = ExpenseService.shared
    @State private var selectedYear = Calendar.current.component(.year, from: Date())
    @State private var selectedMonth: String?
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    filterSection
                    if let error = viewModel.errorMessage {
                        SpendyMessage(message: error)
                    }
                    if viewModel.isLoading {
                        ProgressView("Aggiornamento analisi…").frame(maxWidth: .infinity)
                    }
                    Text(viewModel.appliedFilterDescription)
                        .font(.subheadline).foregroundStyle(Color.spendySecondaryText)
                    SpendyCard {
                        VStack(alignment: .leading, spacing: 16) {
                            MetricValue(title: "Uscite totali", value: viewModel.totalBalance, prominent: true)
                            Text("\(viewModel.totalTransactions) movimenti")
                                .font(.caption).foregroundStyle(Color.spendySecondaryText)
                            Divider()
                            let layout = dynamicTypeSize.isAccessibilitySize
                                ? AnyLayout(VStackLayout(alignment: .leading, spacing: 16))
                                : AnyLayout(HStackLayout(alignment: .top, spacing: 16))
                            layout {
                                MetricValue(title: "Spesa media", value: viewModel.averageExpense)
                                MetricValue(title: "Uscita maggiore", value: viewModel.highestExpense)
                            }
                        }
                    }
                    chartSection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Spese per categoria").font(.headline).accessibilityAddTraits(.isHeader)
                        if viewModel.topCategories.isEmpty && !viewModel.isLoading {
                            SpendyEmptyState(title: "Nessuna uscita",
                                             message: "Le categorie appariranno quando ci saranno spese nel periodo selezionato.",
                                             icon: "chart.pie")
                        } else {
                            SpendyCard(padding: 0) {
                                VStack(spacing: 0) {
                                    ForEach(viewModel.topCategories) { category in
                                        CategoryRow(category: category, maxAmount: viewModel.topCategories.first?.amount ?? 0)
                                        if category.id != viewModel.topCategories.last?.id {
                                            Divider().padding(.horizontal, 16)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                .frame(maxWidth: SpendyLayout.contentWidth)
                .padding(SpendyLayout.pagePadding)
                .frame(maxWidth: .infinity)
            }
            .background(Color.spendyBackground)
            .navigationTitle("Analisi")
            .navigationBarTitleDisplayMode(.inline)
            .task(id: service.revision) { await viewModel.loadIfNeeded() }
            .task(id: "\(selectedYear)-\(service.revision)") {
                selectedMonth = nil
                await viewModel.fetchMonthlyStats(year: selectedYear)
            }
            .refreshable {
                await viewModel.applyFilters()
                await viewModel.fetchMonthlyStats(year: selectedYear)
            }
        }
    }

    private var filterSection: some View {
        SpendyCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Periodo delle spese").font(.headline).accessibilityAddTraits(.isHeader)
                Picker("Periodo", selection: $viewModel.filterMode) {
                    ForEach(AnalyticsViewModel.FilterMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                if viewModel.filterMode == .month {
                    Picker("Mese", selection: $viewModel.selectedMonth) {
                        ForEach(1...12, id: \.self) { month in
                            Text(Calendar.current.monthSymbols[month - 1]).tag(month)
                        }
                    }
                    Picker("Anno", selection: $viewModel.selectedYearInt) {
                        ForEach(years, id: \.self) { year in Text(String(year)).tag(year) }
                    }
                } else if viewModel.filterMode == .dateRange {
                    DatePicker("Da", selection: $viewModel.selectedDateRange.start, displayedComponents: .date)
                    DatePicker("A", selection: $viewModel.selectedDateRange.end, displayedComponents: .date)
                }
                SpendyButton("Applica filtri", variant: .secondary, isLoading: viewModel.isLoading) {
                    Task { await viewModel.applyFilters() }
                }
            }
            .disabled(viewModel.isLoading)
        }
    }

    private var years: ClosedRange<Int> {
        2020...max(2030, Calendar.current.component(.year, from: Date()))
    }

    private var chartSection: some View {
        SpendyCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Andamento mensile").font(.headline).accessibilityAddTraits(.isHeader)
                Picker("Anno del grafico", selection: $selectedYear) {
                    ForEach(years, id: \.self) { year in Text(String(year)).tag(year) }
                }
                Text("Il grafico mostra l'intero anno, indipendentemente dal filtro delle spese.")
                    .font(.caption).foregroundStyle(Color.spendySecondaryText)
                if viewModel.isChartLoading {
                    ProgressView("Caricamento grafico…").frame(maxWidth: .infinity, minHeight: 180)
                } else if let error = viewModel.chartError {
                    SpendyMessage(message: error)
                    Button("Riprova") { Task { await viewModel.fetchMonthlyStats(year: selectedYear) } }
                } else if viewModel.monthlyData.allSatisfy({ $0.amount == 0 }) {
                    SpendyEmptyState(title: "Nessun dato per questo anno",
                                     message: "Scegli un altro anno per consultare le spese.", icon: "chart.bar")
                } else {
                    Chart(viewModel.monthlyData) { item in
                        BarMark(x: .value("Mese", item.month), y: .value("Uscite", item.amount))
                            .foregroundStyle(Color.spendyPrimary)
                            .cornerRadius(3)
                            .accessibilityLabel(item.month)
                            .accessibilityValue(item.amount.formatted(.currency(code: "EUR")))
                    }
                    .chartXSelection(value: $selectedMonth)
                    .chartYAxis { AxisMarks(position: .leading) }
                    .frame(height: 220)
                    if let selectedMonth,
                       let item = viewModel.monthlyData.first(where: { $0.month == selectedMonth }) {
                        Text("\(item.month): \(item.amount.formatted(.currency(code: "EUR")))")
                            .font(.subheadline.weight(.semibold))
                    }
                }
            }
        }
    }
}

private struct MetricValue: View {
    let title: String
    let value: Double
    var prominent = false
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.subheadline).foregroundStyle(Color.spendySecondaryText)
            Text(value, format: .currency(code: "EUR"))
                .font(prominent ? .largeTitle.bold() : .headline).monospacedDigit()
                .foregroundStyle(prominent ? Color.spendyPrimary : Color.spendyText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct CategoryRow: View {
    let category: AnalyticsViewModel.CategoryMetric
    let maxAmount: Double
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            let layout = dynamicTypeSize.isAccessibilitySize
                ? AnyLayout(VStackLayout(alignment: .leading, spacing: 8))
                : AnyLayout(HStackLayout(alignment: .top, spacing: 12))
            layout {
                VStack(alignment: .leading, spacing: 4) {
                    Label(category.name, systemImage: CategoryMapper.icon(for: category.name))
                        .font(.subheadline.weight(.medium))
                    Text("\(category.count) movimenti").font(.caption).foregroundStyle(Color.spendySecondaryText)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Text(category.amount, format: .currency(code: "EUR"))
                    .font(.subheadline.weight(.semibold)).monospacedDigit()
                    .fixedSize(horizontal: false, vertical: true)
            }
            ProgressView(value: maxAmount > 0 ? min(category.amount / maxAmount, 1) : 0)
                .tint(CategoryMapper.color(for: category.name)).accessibilityHidden(true)
        }
        .padding(16)
        .accessibilityElement(children: .combine)
    }
}
