import Foundation

enum TransactionInput {
    /// Accept either decimal separator without silently accepting grouping or non-finite values.
    static func amount(from text: String, allowsZero: Bool = false) -> Double? {
        let value = text.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ",", with: ".")
        guard !value.isEmpty,
              value.allSatisfy({ $0.isASCII && ($0.isNumber || $0 == ".") }),
              value.filter({ $0 == "." }).count <= 1,
              let amount = Double(value), amount.isFinite, amount >= 0, (allowsZero || amount > 0) else { return nil }
        return amount
    }

    static func backendDate(_ date: Date) -> String {
        formatter.string(from: date)
    }

    private static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }()
}
