import Foundation
import SwiftData

@Model
class Expense: Codable, Identifiable {
    @Attribute(.unique) var id: String?
    var type: String
    var product: String
    var startedDate: String?
    var completedDate: String?
    var userDescription: String // Mappato su "description" del JSON
    var amount: Double
    var fee: Double?
    var currency: String?
    var state: String?
    var category: String?
    
    // Mappatura chiavi JSON <-> Swift
    enum CodingKeys: String, CodingKey {
        case id, type, product, startedDate, completedDate, amount, fee, currency, state, category
        case userDescription = "description"
    }

    init(id: String? = nil, type: String = "", product: String = "", startedDate: String? = nil, completedDate: String? = nil, userDescription: String = "", amount: Double = 0.0, fee: Double? = nil, currency: String? = nil, state: String? = nil, category: String? = nil) {
        self.id = id
        self.type = type
        self.product = product
        self.startedDate = startedDate
        self.completedDate = completedDate
        self.userDescription = userDescription
        self.amount = amount
        self.fee = fee
        self.currency = currency
        self.state = state
        self.category = category
    }
    
    // Decodifica necessaria per SwiftData + Codable
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(String.self, forKey: .id)
        self.type = try container.decode(String.self, forKey: .type)
        self.product = try container.decode(String.self, forKey: .product)
        self.startedDate = try container.decodeIfPresent(String.self, forKey: .startedDate)
        self.completedDate = try container.decodeIfPresent(String.self, forKey: .completedDate)
        self.userDescription = try container.decode(String.self, forKey: .userDescription)
        self.amount = try container.decode(Double.self, forKey: .amount)
        self.fee = try container.decodeIfPresent(Double.self, forKey: .fee)
        self.currency = try container.decodeIfPresent(String.self, forKey: .currency)
        self.state = try container.decodeIfPresent(String.self, forKey: .state)
        self.category = try container.decodeIfPresent(String.self, forKey: .category)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(type, forKey: .type)
        try container.encode(product, forKey: .product)
        try container.encode(startedDate, forKey: .startedDate)
        try container.encode(completedDate, forKey: .completedDate)
        try container.encode(userDescription, forKey: .userDescription)
        try container.encode(amount, forKey: .amount)
        try container.encode(fee, forKey: .fee)
        try container.encode(currency, forKey: .currency)
        try container.encode(state, forKey: .state)
        try container.encode(category, forKey: .category)
    }
}
