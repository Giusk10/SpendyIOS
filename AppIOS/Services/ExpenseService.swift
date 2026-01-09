import Foundation
import Combine

@MainActor
class ExpenseService: ObservableObject {
    static let shared = ExpenseService()
    
    private let baseURL = "http://100.117.226.152:8080/Expense/rest/expense"
    
    private init() {}
    
    func fetchExpenses() async throws -> [Expense] {
        return try await performRequest(endpoint: "/getExpenses", responseType: [Expense].self)
    }
    
    func addExpense(_ expense: Expense) async throws {
        let body: [String: String] = [
            "type": expense.type,
            "product": expense.product,
            "startedDate": expense.startedDate ?? "",
            "completedDate": expense.completedDate ?? "",
            "description": expense.userDescription,
            "amount": String(expense.amount),
            "fee": String(expense.fee ?? 0.0),
            "currency": expense.currency ?? "EUR",
            "state": expense.state ?? "",
            "category": expense.category ?? ""
        ]
        
        // Response type is Expense.self based on previous code
        let _: Expense = try await performRequest(endpoint: "/addExpense", method: "POST", body: body, responseType: Expense.self)
    }
    
    func deleteExpense(_ expense: Expense) async throws {
        let body = ["expenseId": expense.id]
        try await performRequestNoResponse(endpoint: "/deleteExpense", method: "DELETE", body: body)
    }
    
    func importCSV(data: Data, fileName: String) async throws -> Bool {
        return try await uploadFile(endpoint: "/import", fileData: data, fileName: fileName)
    }
    
    func deleteAllExpenses() async throws {
        let expenses = try await fetchExpenses()
        for expense in expenses {
            try await deleteExpense(expense)
        }
    }
    
    func getMonthlyStats(year: Int) async -> [String: Double]? {
         let body = [
            "year": String(year)
        ]
        return try? await performRequest(endpoint: "/getMonthlyAmountOfYear", method: "POST", body: body, responseType: [String: Double].self)
    }
    
    func fetchExpensesByDate(start: Date, end: Date) async throws -> [Expense] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        let body = [
            "startedDate": formatter.string(from: start),
            "completedDate": formatter.string(from: end)
        ]
        
        return try await performRequest(endpoint: "/getExpenseByDate", method: "POST", body: body, responseType: [Expense].self)
    }
    
    func fetchExpensesByMonth(month: Int, year: Int) async throws -> [Expense] {
        let body = [
            "month": String(month),
            "year": String(year)
        ]
        
        return try await performRequest(endpoint: "/getExpenseByMonth", method: "POST", body: body, responseType: [Expense].self)
    }
    
    // MARK: - Private Networking Helpers
    private func performRequest<T: Decodable>(endpoint: String, method: String = "GET", body: Any? = nil, responseType: T.Type) async throws -> T {
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = AuthManager.shared.getToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        if let body = body {
            request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        if httpResponse.statusCode == 401 {
            AuthManager.shared.logout()
            throw URLError(.userAuthenticationRequired)
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
        
        // Handle Empty Response for String
        if responseType == String.self, data.isEmpty {
            return "" as! T
        }
        
        // Handle 204 No Content with expected array response
        if httpResponse.statusCode == 204, data.isEmpty {
            if let emptyList = try? JSONDecoder().decode(T.self, from: "[]".data(using: .utf8)!) {
                return emptyList
            }
        }
        
        return try JSONDecoder().decode(T.self, from: data)
    }
    
    private func performRequestNoResponse(endpoint: String, method: String = "GET", body: Any? = nil) async throws {
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = AuthManager.shared.getToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        if let body = body {
            request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        }
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        if httpResponse.statusCode == 401 {
            AuthManager.shared.logout()
            throw URLError(.userAuthenticationRequired)
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
    }
    
    private func uploadFile(endpoint: String, fileData: Data, fileName: String) async throws -> Bool {
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            return false
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        if let token = AuthManager.shared.getToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        var data = Data()
        
        data.append("--\(boundary)\r\n".data(using: .utf8)!)
        data.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
        data.append("Content-Type: text/csv\r\n\r\n".data(using: .utf8)!)
        data.append(fileData)
        data.append("\r\n".data(using: .utf8)!)
        data.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = data
        
        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else { return false }
        
        if httpResponse.statusCode == 401 {
            AuthManager.shared.logout()
            return false
        }
        
        return (200...299).contains(httpResponse.statusCode)
    }
}
