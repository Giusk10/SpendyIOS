import Foundation
import Observation

@MainActor
@Observable
final class AnalyticsViewModel {
    private(set) var totalBalance = 0.0
    private(set) var averageExpense = 0.0
    private(set) var highestExpense = 0.0
    private(set) var totalTransactions = 0
    private(set) var monthlyData: [MonthlyMetric] = []
    private(set) var topCategories: [CategoryMetric] = []
    private(set) var isLoading = false
    private(set) var isChartLoading = false
    var errorMessage: String?
    var chartError: String?
    var filterMode: FilterMode = .all
    var selectedDateRange: (start: Date, end: Date) = (Date(), Date())
    var selectedMonth = Calendar.current.component(.month, from: Date())
    var selectedYearInt = Calendar.current.component(.year, from: Date())
    private var loadedRevision: Int?
    private var requestID = UUID()
    private var chartRequestID = UUID()
    private(set) var appliedFilterDescription = "Tutte le spese"

    enum FilterMode: String, CaseIterable {
        case all = "Tutte"
        case month = "Mese"
        case dateRange = "Intervallo"
    }

    struct MonthlyMetric: Identifiable {
        var id: Date { date }
        let month: String
        let amount: Double
        let date: Date
    }

    struct CategoryMetric: Identifiable {
        var id: String { name }
        let name: String
        let amount: Double
        let count: Int
    }

    func loadIfNeeded() async {
        if loadedRevision != ExpenseService.shared.revision { await applyFilters() }
    }

    func applyFilters() async {
        if filterMode == .dateRange && selectedDateRange.start > selectedDateRange.end {
            errorMessage = "La data finale deve essere successiva alla data iniziale."
            return
        }
        let id = UUID()
        requestID = id
        let revision = ExpenseService.shared.revision
        let mode = filterMode
        isLoading = true
        errorMessage = nil
        defer { if requestID == id { isLoading = false } }
        do {
            let expenses: [Expense]
            switch mode {
            case .all:
                expenses = try await ExpenseService.shared.fetchExpenses()
            case .month:
                expenses = try await ExpenseService.shared.fetchExpensesByMonth(
                    month: selectedMonth, year: selectedYearInt)
            case .dateRange:
                expenses = try await ExpenseService.shared.fetchExpensesByDate(
                    start: selectedDateRange.start, end: selectedDateRange.end)
            }
            try Task.checkCancellation()
            guard requestID == id else { return }
            processExpenses(expenses)
            loadedRevision = revision
            switch mode {
            case .all: appliedFilterDescription = "Tutte le spese"
            case .month:
                appliedFilterDescription = "\(Calendar.current.monthSymbols[selectedMonth - 1]) \(selectedYearInt)"
            case .dateRange:
                appliedFilterDescription = "\(selectedDateRange.start.formatted(date: .abbreviated, time: .omitted)) – \(selectedDateRange.end.formatted(date: .abbreviated, time: .omitted))"
            }
        } catch is CancellationError {
        } catch {
            if !Task.isCancelled { errorMessage = "Impossibile caricare le analisi. \(error.localizedDescription)" }
        }
    }

    private func processExpenses(_ expenses: [Expense]) {
        let outflows = expenses.filter { $0.amount < 0 }

        // 1. Calculate Summaries
        let totalSpending = outflows.reduce(0) { $0 + abs($1.amount) }
        self.totalBalance = totalSpending

        self.totalTransactions = outflows.count
        self.averageExpense = outflows.isEmpty ? 0 : totalSpending / Double(outflows.count)
        self.highestExpense = outflows.map { abs($0.amount) }.max() ?? 0.0

        // 2. Categories
        var categoryMap: [String: (Double, Int)] = [:]
        for expense in outflows {
            // Strictly use the backend category string
            let cat = expense.category ?? "Non classificato"

            let existing = categoryMap[cat] ?? (0.0, 0)
            categoryMap[cat] = (existing.0 + abs(expense.amount), existing.1 + 1)
        }

        self.topCategories = categoryMap.map { key, value in
            CategoryMetric(name: key, amount: value.0, count: value.1)
        }.sorted(by: { $0.amount > $1.amount })
    }


    func fetchMonthlyStats(year: Int) async {
        let id = UUID()
        chartRequestID = id
        isChartLoading = true
        chartError = nil
        defer { if chartRequestID == id { isChartLoading = false } }
        let amounts = await ExpenseService.shared.getMonthlyStats(year: year)
        guard chartRequestID == id, !Task.isCancelled else { return }
        guard let amounts else {
            monthlyData = []
            chartError = "Impossibile caricare l'andamento mensile."
            return
        }
        let calendar = Calendar(identifier: .gregorian)
        monthlyData = (1...12).compactMap { month in
            guard let date = calendar.date(from: DateComponents(year: year, month: month, day: 1)) else { return nil }
            let key = String(format: "%04d-%02d", year, month)
            return MonthlyMetric(month: date.formatted(.dateTime.month(.abbreviated)),
                                 amount: abs(amounts[key] ?? 0), date: date)
        }
    }
}
