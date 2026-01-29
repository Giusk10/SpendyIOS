import Combine
import Foundation

@MainActor
class ExpenseService: ObservableObject {
    static let shared = ExpenseService()

    private let baseURL = "\(Constants.baseURL)/Expense/rest/expense"

    private init() {}

    func fetchExpenses() async throws -> [Expense] {
        guard let url = URL(string: "\(baseURL)/getExpenses") else { throw URLError(.badURL) }
        return try await NetworkManager.shared.performRequest(
            url: url, responseType: [Expense].self)
    }

    func addExpense(_ expense: Expense) async throws {
        guard let url = URL(string: "\(baseURL)/addExpense") else { throw URLError(.badURL) }

        // FIX: Uso le proprietà .xxxString invece delle vecchie .xxxDate
        let body: [String: String] = [
            "type": expense.type,
            "product": expense.product,
            "startedDate": expense.startedDateString ?? "",  // <--- CORRETTO
            "completedDate": expense.completedDateString ?? "",  // <--- CORRETTO
            "description": expense.userDescription,
            "amount": String(expense.amount),
            "fee": String(expense.fee ?? 0.0),
            "currency": expense.currency ?? "EUR",
            "state": expense.state ?? "",
            "category": expense.category ?? "",
        ]

        // Use generic request ignoring return
        let _: Expense = try await NetworkManager.shared.performRequest(
            url: url, method: "POST", body: body, responseType: Expense.self)
    }

    func deleteExpense(_ expense: Expense) async throws {
        guard let url = URL(string: "\(baseURL)/deleteExpense") else { throw URLError(.badURL) }
        let body = ["expenseId": expense.id]
        try await NetworkManager.shared.performRequestNoResponse(
            url: url, method: "DELETE", body: body)
    }

    func updateExpense(_ expense: Expense) async throws {
        guard let url = URL(string: "\(baseURL)/updateExpense") else { throw URLError(.badURL) }

        // FIX: Uso le proprietà .xxxString invece delle vecchie .xxxDate
        let body: [String: Any] = [
            "id": expense.id,
            "type": expense.type,
            "startedDate": expense.startedDateString ?? "",  // <--- CORRETTO
            "completedDate": expense.completedDateString ?? "",  // <--- CORRETTO
            "description": expense.userDescription,
            "amount": expense.amount,
        ]

        let _: Expense = try await NetworkManager.shared.performRequest(
            url: url, method: "POST", body: body, responseType: Expense.self)
    }

    func importCSV(data: Data, fileName: String) async throws -> Bool {
        // UploadFile logic
        return try await uploadFile(endpoint: "/import", fileData: data, fileName: fileName)
    }

    func deleteAllExpenses() async throws {
        guard let url = URL(string: "\(baseURL)/deleteAllExpenses") else { throw URLError(.badURL) }
        try await NetworkManager.shared.performRequestNoResponse(url: url, method: "DELETE")
    }

    func getMonthlyStats(year: Int) async -> [String: Double]? {
        guard let url = URL(string: "\(baseURL)/getMonthlyAmountOfYear") else { return nil }
        let body = [
            "year": String(year)
        ]
        return try? await NetworkManager.shared.performRequest(
            url: url, method: "POST", body: body, responseType: [String: Double].self)
    }

    func fetchExpensesByDate(start: Date, end: Date) async throws -> [Expense] {
        guard let url = URL(string: "\(baseURL)/getExpenseByDate") else { throw URLError(.badURL) }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        let body = [
            "startedDate": formatter.string(from: start),
            "completedDate": formatter.string(from: end),
        ]

        return try await NetworkManager.shared.performRequest(
            url: url, method: "POST", body: body, responseType: [Expense].self)
    }

    func fetchExpensesByMonth(month: Int, year: Int) async throws -> [Expense] {
        guard let url = URL(string: "\(baseURL)/getExpenseByMonth") else { throw URLError(.badURL) }

        let body = [
            "month": String(format: "%02d", month),
            "year": String(year),
        ]

        return try await NetworkManager.shared.performRequest(
            url: url, method: "POST", body: body, responseType: [Expense].self)
    }

    // MARK: - Private Helper for Upload (Custom Multipart)
    private func uploadFile(endpoint: String, fileData: Data, fileName: String) async throws -> Bool
    {
        guard let url = URL(string: "\(baseURL)\(endpoint)") else { return false }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        let boundary = UUID().uuidString
        request.setValue(
            "multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        // Inject Token
        if let token = AuthManager.shared.getAccessToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        var data = Data()
        data.append("--\(boundary)\r\n".data(using: .utf8)!)
        data.append(
            "Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\r\n".data(
                using: .utf8)!)
        data.append("Content-Type: text/csv\r\n\r\n".data(using: .utf8)!)
        data.append(fileData)
        data.append("\r\n".data(using: .utf8)!)
        data.append("--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = data

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else { return false }

            if httpResponse.statusCode == 401 {
                AuthManager.shared.logout()
                return false
            }

            return (200...299).contains(httpResponse.statusCode)
        } catch {
            return false
        }
    }
}
