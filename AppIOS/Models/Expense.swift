import Foundation

// MARK: - Date Parser Helper
struct DateParser {
    private static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

    private static let formats = [
        "yyyy-MM-dd'T'HH:mm:ss.SSSZ",
        "yyyy-MM-dd'T'HH:mm:ssZ",
        "yyyy-MM-dd'T'HH:mm:ss",
        "yyyy-MM-dd HH:mm:ss",
        "yyyy-MM-dd",
        "dd/MM/yyyy",
        "dd-MM-yyyy",
    ]

    static func parse(_ string: String?) -> Date? {
        guard let string = string, !string.isEmpty else { return nil }

        for format in formats {
            formatter.dateFormat = format
            if let date = formatter.date(from: string) {
                return date
            }
        }
        return nil
    }
}

// MARK: - Expense Model
struct Expense: Identifiable, Codable, Equatable {
    let id: String
    let type: String
    let product: String
    let startedDateString: String?  // Stringa originale per il JSON
    let completedDateString: String?
    let userDescription: String
    let amount: Double
    let fee: Double?
    let currency: String?
    let state: String?
    let category: String?

    // Proprietà locale ottimizzata (NON viene salvata nel JSON, serve solo alla UI)
    let date: Date?

    enum CodingKeys: String, CodingKey {
        case id, type, product, amount, fee, currency, state, category
        case startedDate  // Nel JSON la chiave è "startedDate"
        case completedDate
        case userDescription = "description"
    }

    // Init manuale
    init(
        id: String = UUID().uuidString,
        type: String = "SPESA",
        product: String = "",
        startedDate: String? = nil,
        completedDate: String? = nil,
        description: String = "",
        amount: Double = 0.0,
        fee: Double? = nil,
        currency: String? = nil,
        state: String? = nil,
        category: String? = nil
    ) {

        self.id = id
        self.type = type
        self.product = product
        self.startedDateString = startedDate
        self.completedDateString = completedDate
        self.userDescription = description
        self.amount = amount
        self.fee = fee
        self.currency = currency
        self.state = state
        self.category = category

        self.date = DateParser.parse(startedDate)
    }

    // MARK: - Decodable (Dal JSON alla Struct)
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = try container.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
        self.type = try container.decodeIfPresent(String.self, forKey: .type) ?? "SPESA"
        self.product = try container.decodeIfPresent(String.self, forKey: .product) ?? ""

        // Mappatura date
        let sDate = try container.decodeIfPresent(String.self, forKey: .startedDate)
        self.startedDateString = sDate
        self.completedDateString = try container.decodeIfPresent(
            String.self, forKey: .completedDate)

        self.userDescription =
            try container.decodeIfPresent(String.self, forKey: .userDescription) ?? ""
        self.amount = try container.decodeIfPresent(Double.self, forKey: .amount) ?? 0.0
        self.fee = try container.decodeIfPresent(Double.self, forKey: .fee)
        self.currency = try container.decodeIfPresent(String.self, forKey: .currency)
        self.state = try container.decodeIfPresent(String.self, forKey: .state)
        self.category = try container.decodeIfPresent(String.self, forKey: .category)

        // Calcolo ottimizzato della data
        self.date = DateParser.parse(sDate)
    }

    // MARK: - Encodable (Dalla Struct al JSON)
    // È necessario implementarlo manualmente perché 'date' non va nel JSON
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(id, forKey: .id)
        try container.encode(type, forKey: .type)
        try container.encode(product, forKey: .product)
        try container.encode(amount, forKey: .amount)
        try container.encodeIfPresent(fee, forKey: .fee)
        try container.encodeIfPresent(currency, forKey: .currency)
        try container.encodeIfPresent(state, forKey: .state)
        try container.encodeIfPresent(category, forKey: .category)
        try container.encode(userDescription, forKey: .userDescription)

        // Salviamo le stringhe originali nelle chiavi corrette
        try container.encodeIfPresent(startedDateString, forKey: .startedDate)
        try container.encodeIfPresent(completedDateString, forKey: .completedDate)

        // Nota: self.date viene ignorato perché è una proprietà derivata
    }

    static func == (lhs: Expense, rhs: Expense) -> Bool {
        return lhs.id == rhs.id && lhs.amount == rhs.amount
            && lhs.userDescription == rhs.userDescription && lhs.date == rhs.date
    }
}
