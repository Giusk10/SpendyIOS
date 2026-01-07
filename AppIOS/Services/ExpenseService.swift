import Foundation

import Foundation
import SwiftData

@MainActor
class ExpenseService {
    static let shared = ExpenseService()
    var modelContext: ModelContext?

    private init() {}
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }
    
    func fetchExpenses() throws -> [Expense] {
        guard let context = modelContext else { return [] }
        let descriptor = FetchDescriptor<Expense>(sortBy: [SortDescriptor(\.startedDate, order: .reverse)])
        return try context.fetch(descriptor)
    }
    
    func addExpense(_ expense: Expense) {
        modelContext?.insert(expense)
    }
    
    func deleteExpense(_ expense: Expense) {
        modelContext?.delete(expense)
    }
    
    func importCSV(url: URL) throws -> Int {
        guard let context = modelContext else { return 0 }
        
        let data = try String(contentsOf: url, encoding: .utf8)
        var rows = data.components(separatedBy: "\n")
        
        // Filter out empty lines
        rows = rows.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        
        var count = 0
        
        // Skip header if exists
        for (index, row) in rows.enumerated() {
            if index == 0 { continue }
            
            let columns = row.components(separatedBy: ",")
            let cleanColumns = columns.map { $0.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "\"", with: "") }
            
            if cleanColumns.count >= 3 {
                let date = cleanColumns[0]
                let description = cleanColumns[1]
                
                if let amount = Double(cleanColumns[2]) {
                    let category = cleanColumns.count > 3 ? cleanColumns[3] : nil
                    
                    let expense = Expense(
                        type: "Expense",
                        product: "Imported",
                        startedDate: date,
                        completedDate: date,
                        description: description,
                        amount: amount,
                        category: category
                    )
                    context.insert(expense)
                    count += 1
                }
            }
        }
        
        // Explicitly save to ensure persistence immediately
        try? context.save()
        return count
    }
    
    // Kept for compatibility but logic is now local filtering
    func fetchExpensesByDate(start: String, end: String) throws -> [Expense] {
        let all = try fetchExpenses()
        return all.filter { ($0.startedDate ?? "") >= start && ($0.startedDate ?? "") <= end }
    }
}
