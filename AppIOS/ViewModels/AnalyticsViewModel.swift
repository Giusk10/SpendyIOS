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
    
    // Alias to fix capitalization for public use if preferred, but struct above is internal helper
    typealias MonthlyMetric = monthlyMetric
    
    struct CategoryMetric: Identifiable {
        var id: String { name }
        let name: String
        let amount: Double
        let count: Int
    }
    
    func loadData() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let expenses = try await ExpenseService.shared.fetchExpenses()
                processExpenses(expenses)
                isLoading = false
            } catch {
                isLoading = false
                errorMessage = "Failed to load data: \(error.localizedDescription)"
            }
        }
    }
    
    private func processExpenses(_ expenses: [Expense]) {
        // Filter valid expenses (ignore those without amount etc if any, though model enforces it)
        // Expenses are usually negative for spending? 
        // User screenshot shows positive numbers for "USCITE".
        // Our AddExpense uses negative. Dashboard shows green/red.
        // Let's assume we want to show absolute values for "Spending" analysis,
        // or just sum them up. 
        // Screenshot: "Uscite Totali: 847,41 €". "Uscita Maggiore: 247,00 €".
        // This implies we look at the magnitude of negative numbers (outflows).
        
        let outflows = expenses.filter { $0.amount < 0 }
        
        // 1. Total Balance (Balance implies net, but "Uscite Totali" implies User wants total spending)
        // However, "Total Balance" in dashboard is net.
        // The request says "grafico e statistiche come nel mio sito" and attaches image of "Uscite Totali".
        // So I will implement "Total Spending" (sum of abs(negative)).
        
        let totalSpending = outflows.reduce(0) { $0 + abs($1.amount) }
        self.totalBalance = totalSpending
        
        self.totalTransactions = outflows.count
        
        // 2. Average
        self.averageExpense = outflows.isEmpty ? 0 : totalSpending / Double(outflows.count)
        
        // 3. Highest
        self.highestExpense = outflows.map { abs($0.amount) }.max() ?? 0.0
        
        // 4. Monthly Trend - Fetch from Server
        // We will fetch this separately or we can trigger it here if year is known.
        // For now, removing manual aggregation as we will use fetchMonthlyStats
    }
    
    func fetchMonthlyStats(year: String) {
        Task {
            if let amounts = await ExpenseService.shared.getMonthlyStats(year: year) {
                await MainActor.run {
                    self.monthlyData = processMonthlyStats(amounts, year: year)
                }
            }
        }
    }
    
    private func processMonthlyStats(_ amounts: [Double], year: String) -> [MonthlyMetric] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM"
        let calendar = Calendar.current
        var metrics: [MonthlyMetric] = []
        
        for (index, amount) in amounts.enumerated() {
            // Create a date for this month/year for correct sorting and label
            var components = DateComponents()
            components.year = Int(year)
            components.month = index + 1 // 1-based
            components.day = 1
            
            if let date = calendar.date(from: components) {
                let monthName = dateFormatter.string(from: date)
                // Filter out zero months if desired, or keep them for the chart continuity
                // Keeping them is usually better for a "Trend" line
                metrics.append(MonthlyMetric(month: monthName, amount: amount, date: date))
            }
        }
        
        return metrics
    }
    
    func updateFilters(year: String) {
        fetchMonthlyStats(year: year)
        // Future: Filter expenses list by year if needed, currently we just load all.
    }
}
