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
        
        guard let headerRow = rows.first else { return 0 }
        let headers = headerRow.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "\"", with: "") }
        
        // Find indices
        let typeIndex = headers.firstIndex(of: "Tipo") ?? -1
        let productIndex = headers.firstIndex(of: "Prodotto") ?? -1
        let startedDateIndex = headers.firstIndex(of: "Data di inizio") ?? -1
        let completedDateIndex = headers.firstIndex(of: "Data di completamento") ?? -1
        let descriptionIndex = headers.firstIndex(of: "Descrizione") ?? -1
        let amountIndex = headers.firstIndex(of: "Importo") ?? -1
        let currencyIndex = headers.firstIndex(of: "Valuta") ?? -1
        let stateIndex = headers.firstIndex(of: "State") ?? -1
        
        var count = 0
        
        for (index, row) in rows.enumerated() {
            if index == 0 { continue }
            
            // Handle comma inside quotes if necessary, simpler split for now assuming no commas in fields based on sample
            let columns = row.components(separatedBy: ",")
            let cleanColumns = columns.map { $0.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "\"", with: "") }
            
            // Ensure we have enough columns for the max index we need
            guard cleanColumns.count > max(typeIndex, productIndex, startedDateIndex, descriptionIndex, amountIndex) else { continue }
            
            let amountString = (amountIndex >= 0) ? cleanColumns[amountIndex] : "0"
            if let amount = Double(amountString) {
                let expense = Expense(
                    type: (typeIndex >= 0) ? cleanColumns[typeIndex] : "",
                    product: (productIndex >= 0) ? cleanColumns[productIndex] : "",
                    startedDate: (startedDateIndex >= 0) ? cleanColumns[startedDateIndex] : nil,
                    completedDate: (completedDateIndex >= 0) ? cleanColumns[completedDateIndex] : nil,
                    description: (descriptionIndex >= 0) ? cleanColumns[descriptionIndex] : "Imported",
                    amount: amount,
                    currency: (currencyIndex >= 0) ? cleanColumns[currencyIndex] : nil,
                    state: (stateIndex >= 0) ? cleanColumns[stateIndex] : nil
                )
                context.insert(expense)
                count += 1
            }
        }
        
        try? context.save()
        return count
    }
    
    // Kept for compatibility but logic is now local filtering
    func fetchExpensesByDate(start: String, end: String) throws -> [Expense] {
        let all = try fetchExpenses()
        return all.filter { ($0.startedDate ?? "") >= start && ($0.startedDate ?? "") <= end }
    }
}
