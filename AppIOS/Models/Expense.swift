import Foundation

struct Expense: Codable, Identifiable {
    var id: String?
    var type: String
    var product: String
    var startedDate: String?
    var completedDate: String?
    var description: String
    var amount: Double
    var fee: Double?
    var currency: String?
    var state: String?
    var category: String?
}

struct AggregatedExpenseMetrics: Codable {
    var totalExpenses: Double
    var averageExpense: Double
    var highestExpense: Double
    var totalTransactions: Int
    var categories: [CategoryMetric]
    
    struct CategoryMetric: Codable {
        var name: String
        var total: Double
        var transactions: Int
    }
}
