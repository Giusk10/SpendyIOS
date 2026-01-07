import Foundation

struct ExpenseService {
    static let shared = ExpenseService()
    private init() {}
    
    func fetchExpenses() async throws -> [Expense] {
        return try await HTTPClient.shared.request(endpoint: "/Expense/rest/expense/getExpenses", method: "GET")
    }
    
    func fetchExpensesByDate(start: String, end: String) async throws -> [Expense] {
        struct DateRangePayload: Encodable {
            let startedDate: String
            let completedDate: String
        }
        let payload = DateRangePayload(startedDate: start, completedDate: end)
        return try await HTTPClient.shared.request(endpoint: "/Expense/rest/expense/getExpenseByDate", method: "POST", body: payload)
    }
    
    func fetchExpensesByMonth(month: String, year: String) async throws -> [Expense] {
         struct MonthPayload: Encodable {
            let month: String
            let year: String
        }
        let payload = MonthPayload(month: month, year: year)
        return try await HTTPClient.shared.request(endpoint: "/Expense/rest/expense/getExpenseByMonth", method: "POST", body: payload)
    }
    
    func fetchMonthlyAmountOfYear(year: String) async throws -> [String: AnyCodable] {
        // Using AnyCodable wrapper or specific struct if structure is known. 
        // Based on TS: Record<string, number | string>
        // Swift Dictionary values must be same type. decoding mixed types is tricky.
        // For now, let's assume it returns a raw dictionary or map to specific model.
        // Returing raw data or a simplified model might be safer.
        // Let's implement a wrapper.
        return try await HTTPClient.shared.request(endpoint: "/Expense/rest/expense/getMonthlyAmountOfYear", method: "POST", body: ["year": year])
    }
}

// Minimal AnyCodable wrapper for mixed JSON values
enum AnyCodable: Codable {
    case string(String)
    case double(Double)
    case int(Int)
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let x = try? container.decode(Double.self) {
            self = .double(x)
            return
        }
        if let x = try? container.decode(Int.self) {
            self = .int(x)
            return
        }
        if let x = try? container.decode(String.self) {
            self = .string(x)
            return
        }
        throw DecodingError.typeMismatch(AnyCodable.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Wrong type for AnyCodable"))
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let x): try container.encode(x)
        case .double(let x): try container.encode(x)
        case .int(let x): try container.encode(x)
        }
    }
}
