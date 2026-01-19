import Foundation
import Combine

@MainActor
class AnalyticsViewModel: ObservableObject {
    @Published var totalBalance: Double = 0.0
    @Published var averageExpense: Double = 0.0
    @Published var highestExpense: Double = 0.0
    @Published var totalTransactions: Int = 0
    @Published var monthlyData: [MonthlyMetric] = []
    @Published var topCategories: [CategoryMetric] = []
    
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    struct monthlyMetric: Identifiable {
        var id: String { month }
        let month: String
        let amount: Double
        let date: Date // For sorting
    }
    typealias MonthlyMetric = monthlyMetric
    
    struct CategoryMetric: Identifiable {
        var id: String { name }
        let name: String
        let amount: Double
        let count: Int
    }
    
    // Filter State
    @Published var filterMode: FilterMode = .all
    @Published var selectedDateRange: (start: Date, end: Date) = (Date(), Date())
    @Published var selectedMonth: Int = Calendar.current.component(.month, from: Date())
    @Published var selectedYearInt: Int = Calendar.current.component(.year, from: Date())
    
    enum FilterMode {
        case all
        case month
        case dateRange
    }
    
    func loadData() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let expenses = try await ExpenseService.shared.fetchExpenses()
                await MainActor.run {
                    processExpenses(expenses)
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Failed to load data: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func applyFilters() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                var expenses: [Expense] = []
                
                switch filterMode {
                case .all:
                    expenses = try await ExpenseService.shared.fetchExpenses()
                case .month:
                    expenses = try await ExpenseService.shared.fetchExpensesByMonth(month: selectedMonth, year: selectedYearInt)
                case .dateRange:
                    expenses = try await ExpenseService.shared.fetchExpensesByDate(start: selectedDateRange.start, end: selectedDateRange.end)
                }
                
                await MainActor.run {
                    processExpenses(expenses)
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Failed to load expenses: \(error.localizedDescription)"
                }
            }
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
            let cat = expense.category ?? "Uncategorized"
            let existing = categoryMap[cat] ?? (0.0, 0)
            categoryMap[cat] = (existing.0 + abs(expense.amount), existing.1 + 1)
        }
        
        self.topCategories = categoryMap.map { key, value in
            CategoryMetric(name: key, amount: value.0, count: value.1)
        }.sorted(by: { $0.amount > $1.amount })
        
        
        self.topCategories = categoryMap.map { key, value in
            CategoryMetric(name: key, amount: value.0, count: value.1)
        }.sorted(by: { $0.amount > $1.amount })
    }
    
    // Legacy/Comparison method - can keep or remove if we rely fully on local agg
    func fetchMonthlyStats(year: String) {
        guard let yearInt = Int(year) else { return }
        
        Task {
            if let amounts = await ExpenseService.shared.getMonthlyStats(year: yearInt) {
                await MainActor.run {
                    self.monthlyData = processMonthlyStats(amounts, year: yearInt)
                }
            }
        }
    }
    
    private func processMonthlyStats(_ amounts: [String: Double], year: Int) -> [MonthlyMetric] {
        let calendar = Calendar.current
        var metrics: [MonthlyMetric] = []
        
        // Output format check: "MMM" for chart calls
        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "MMM"
        
        // Helper to format key
        let keyFormatter = DateFormatter()
        keyFormatter.dateFormat = "yyyy-MM"
        
        for month in 1...12 {
            var components = DateComponents()
            components.year = year
            components.month = month
            components.day = 1
            
            if let date = calendar.date(from: components) {
                let key = keyFormatter.string(from: date)
                let amount = amounts[key] ?? 0.0 // Default to 0 if missing
                let monthName = outputFormatter.string(from: date)
                
                metrics.append(MonthlyMetric(month: monthName, amount: abs(amount), date: date))
            }
        }
        
        return metrics.sorted(by: { $0.date < $1.date })
    }
    
    func updateFilters(year: String) {
        fetchMonthlyStats(year: year)
        selectedYearInt = Int(year) ?? selectedYearInt
    }
}
