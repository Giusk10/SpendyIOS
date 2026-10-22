import Foundation
import Testing
@testable import SpendyLogic

@Suite("Transaction regression checks", .serialized)
struct SpendyLogicTests {
    @Test(arguments: ["12.50", "12,50", " 12,50 "])
    func acceptsDecimalSeparators(_ input: String) {
        #expect(TransactionInput.amount(from: input) == 12.5)
    }

    @Test(arguments: ["", " ", "0", "-12", "NaN", "inf", "1e9", "1,234.50", "1.2.3", "€12", "１２"])
    func rejectsInvalidAmounts(_ input: String) {
        #expect(TransactionInput.amount(from: input) == nil)
    }

    @Test(arguments: ["2026-10-22T12:30:45.123+0000", "2026-10-22T12:30:45+0000",
                      "2026-10-22T12:30:45", "2026-10-22 12:30:45", "2026-10-22",
                      "22/10/2026", "22-10-2026"])
    func preservesAcceptedDateFormats(_ input: String) {
        #expect(DateParser.parse(input) != nil)
    }

    @Test func rejectsMissingDates() {
        #expect(DateParser.parse(nil) == nil)
        #expect(DateParser.parse("") == nil)
        #expect(DateParser.parse("not a date") == nil)
    }

    @Test func editingPreservesZeroAmountSupport() {
        #expect(TransactionInput.amount(from: "0", allowsZero: true) == 0)
        #expect(TransactionInput.amount(from: "-1", allowsZero: true) == nil)
        #expect(TransactionInput.amount(from: "0") == nil)
    }

    @Test func preservesPayloadOnRoundTrip() throws {
        let payload = Data(#"{"id":"expense-1","type":"Imported type","product":"Card","startedDate":"2026-10-22T12:30:45+0000","completedDate":"2026-10-23T09:00:00+0000","description":"Groceries","amount":-42.5,"fee":0.25,"currency":"GBP","state":"COMPLETED","category":"Supermercati e Alimentari"}"#.utf8)
        let expense = try JSONDecoder().decode(Expense.self, from: payload)
        let encoded = try JSONEncoder().encode(expense)
        let original = try #require(JSONSerialization.jsonObject(with: payload) as? NSDictionary)
        let roundTrip = try #require(JSONSerialization.jsonObject(with: encoded) as? NSDictionary)
        #expect(original == roundTrip)
        #expect(roundTrip["date"] == nil)
        #expect(expense.amount == -42.5)
    }

    @Test func equalityIncludesPresentationFields() {
        let first = Expense(id: "same", type: "Carta", amount: -12, currency: "EUR", category: "Varie")
        let categoryChange = Expense(id: "same", type: "Carta", amount: -12, currency: "EUR", category: "Trasporti")
        let currencyChange = Expense(id: "same", type: "Carta", amount: -12, currency: "USD", category: "Varie")
        let typeChange = Expense(id: "same", type: "Contanti", amount: -12, currency: "EUR", category: "Varie")
        #expect(first != categoryChange)
        #expect(first != currencyChange)
        #expect(first != typeChange)
    }

    @Test func backendDateRetainsLocalTimestampContract() throws {
        let date = try #require(DateParser.parse("2026-10-22 12:30:45"))
        #expect(TransactionInput.backendDate(date) == "2026-10-22 12:30:45")
    }
}
