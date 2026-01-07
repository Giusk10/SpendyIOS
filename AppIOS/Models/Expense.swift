import Foundation

import SwiftData

@Model
class Expense: Identifiable {
    @Attribute(.unique) var id: String
    var remoteId: String? // Backend ID
    var type: String
    var product: String
    var startedDate: String?
    var completedDate: String?
    var userDescription: String
    var amount: Double
    var fee: Double?
    var currency: String?
    var state: String?
    var category: String?
    
    // Offline Sync Status
    // 0: Synced, 1: Pending Add, 2: Pending Delete
    var syncStatus: Int = 0 
    
    init(id: String = UUID().uuidString, remoteId: String? = nil, type: String = "", product: String = "", startedDate: String? = nil, completedDate: String? = nil, description: String = "", amount: Double = 0.0, fee: Double? = nil, currency: String? = nil, state: String? = nil, category: String? = nil, syncStatus: Int = 0) {
        self.id = id
        self.remoteId = remoteId
        self.type = type
        self.product = product
        self.startedDate = startedDate
        self.completedDate = completedDate
        self.userDescription = description
        self.amount = amount
        self.fee = fee
        self.currency = currency
        self.state = state
        self.category = category
        self.syncStatus = syncStatus
    }
}

// DTO for Backend Communication
struct ExpenseDTO: Codable {
    var id: String?
    var type: String?
    var product: String?
    var startedDate: String?
    var completedDate: String?
    var description: String?
    var amount: Double?
    var fee: Double?
    var currency: String?
    var state: String?
    var category: String?
    
    // Manual mapping to Model
    func toExpense() -> Expense {
        return Expense(
            remoteId: id,
            type: type ?? "",
            product: product ?? "",
            startedDate: startedDate,
            completedDate: completedDate,
            description: description ?? "",
            amount: amount ?? 0.0,
            fee: fee,
            currency: currency,
            state: state,
            category: category,
            syncStatus: 0
        )
    }
}

extension Expense {
    func toDTO() -> ExpenseDTO {
        return ExpenseDTO(
            id: remoteId, // Send remoteId if updating, or null if new? Backend usually handles ID generation for new.
            type: type,
            product: product,
            startedDate: startedDate,
            completedDate: completedDate,
            description: userDescription,
            amount: amount,
            fee: fee,
            currency: currency,
            state: state,
            category: category
        )
    }
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
