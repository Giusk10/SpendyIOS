import Foundation
import SwiftData
import Combine

@MainActor
class ExpenseService: ObservableObject {
    static let shared = ExpenseService()
    var modelContext: ModelContext?
    
    private init() {}
    
    func setModelContext(_ context: ModelContext) { self.modelContext = context }
    
    func fetchExpenses() async throws -> [Expense] {
        let expenses = try await APIClient.performRequest(endpoint: "/Expense/rest/expense/getExpenses", responseType: [Expense].self)
        if let context = modelContext {
            try? context.delete(model: Expense.self)
            for exp in expenses { context.insert(exp) }
        }
        return expenses
    }
    
    func addExpense(_ expense: Expense) async throws {
        // Mappatura manuale per sicurezza
        let body: [String: Any] = [
            "type": expense.type,
            "product": expense.product,
            "startedDate": expense.startedDate ?? "",
            "completedDate": expense.completedDate ?? "",
            "description": expense.userDescription,
            "amount": expense.amount,
            "fee": expense.fee ?? 0.0,
            "currency": expense.currency ?? "EUR",
            "state": expense.state ?? "",
            "category": expense.category ?? ""
        ]
        let _: Expense = try await APIClient.performRequest(endpoint: "/Expense/rest/expense/addExpense", method: "POST", body: body, responseType: Expense.self)
        modelContext?.insert(expense)
    }
    
    func deleteExpense(_ expense: Expense) async throws {
        guard let id = expense.id else { return }
        try await APIClient.performRequestNoResponse(endpoint: "/Expense/rest/expense/deleteExpense", method: "DELETE", body: ["expenseId": id])
        modelContext?.delete(expense)
    }
    
    func updateExpense(_ expense: Expense) async throws {
        let body: [String: Any] = [
            "id": expense.id ?? "",
            "type": expense.type,
            "product": expense.product,
            "startedDate": expense.startedDate ?? "",
            "completedDate": expense.completedDate ?? "",
            "description": expense.userDescription,
            "amount": expense.amount,
            "fee": expense.fee ?? 0.0,
            "currency": expense.currency ?? "EUR",
            "state": expense.state ?? "",
            "category": expense.category ?? ""
        ]
        
        let _: Expense = try await APIClient.performRequest(endpoint: "/Expense/rest/expense/updateExpense", method: "POST", body: body, responseType: Expense.self)
        
        // Update local model if needed, but SwiftData objects are reference types and 'expense' passed in might be a copy or detached if not careful.
        // Since we are passing 'updatedExpense' which is a copy from the view struct, we need to ensure the SwiftData context is updated if we want offline/local consistency immediately.
        // However, 'expense' usage in DetailView might be the struct copy.
        // Ideally we should save the context if we modified a managed object.
        // But here we are sending to server.
        // Let's assume re-fetching or simplistic flow for now.
        // Wait, 'expense' in DetailView is 'let expense: Expense'. It's a class.
        // If we modify it, we should save context.
        // In this method we receive 'expense'. If it's a managed object, we can save context.
        try? modelContext?.save()
    }
    
    // Le altre tue funzioni (stats, update, etc.) si convertono allo stesso modo usando APIClient.performRequest
    
    func importCSV(data: Data, fileName: String = "expenses.csv") async throws -> Bool {
        let url = URL(string: "\(Constants.baseURL)/Expense/rest/expense/import")!
        let token = await AuthManager.shared.getAccessToken() ?? ""
        var request = URLRequest(url: url); request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: text/csv\r\n\r\n".data(using: .utf8)!)
        body.append(data)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body
        
        let (_, response) = try await URLSession.shared.data(for: request)
        return (response as? HTTPURLResponse)?.statusCode == 200
    }
    
    // MARK: - Missing Methods Implementation
    
    func deleteAllExpenses() async throws {
         // Tentativo endpoint deleteAll
         try await APIClient.performRequestNoResponse(endpoint: "/Expense/rest/expense/deleteAll", method: "DELETE")
         if let context = modelContext {
             try? context.delete(model: Expense.self)
         }
    }
    
    func fetchExpensesByMonth(month: Int, year: Int) async throws -> [Expense] {
        // Fallback: fetch all and filter locally if endpoint is unknown
        let all = try await fetchExpenses()
        let calendar = Calendar.current
        return all.filter { expense in
            guard let dateStr = expense.startedDate,
                  let date = dateFromISO(dateStr) else { return false }
            let comps = calendar.dateComponents([.month, .year], from: date)
            return comps.month == month && comps.year == year
        }
    }
    
    func fetchExpensesByDate(start: Date, end: Date) async throws -> [Expense] {
        // Fallback: fetch all and filter locally
        let all = try await fetchExpenses()
        return all.filter { expense in
             guard let dateStr = expense.startedDate,
                   let date = dateFromISO(dateStr) else { return false }
             return date >= start && date <= end
        }
    }
    
    func getMonthlyStats(year: Int) async throws -> [String: Double] {
        // Endpoint ipotetico o calcolo locale
        // Implementazione locale per sicurezza:
        let all = try await fetchExpenses()
        var stats: [String: Double] = [:]
        
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM" // Formato chiave atteso da AnalyticsViewModel
        
        for expense in all {
             guard let dateStr = expense.startedDate,
                   let date = dateFromISO(dateStr) else { continue }
             let comps = calendar.dateComponents([.year], from: date)
             if comps.year == year {
                 let key = formatter.string(from: date)
                 let amount = expense.amount
                 // Somma solo le spese negative o tutte? AnalyticsViewModel sembra aspettarsi amounts.
                 // AnalyticsViewModel fa abs() poi.
                 stats[key, default: 0.0] += amount
             }
        }
        return stats
    }
    
    private func dateFromISO(_ string: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: string) ?? ISO8601DateFormatter().date(from: string)
    }
}
