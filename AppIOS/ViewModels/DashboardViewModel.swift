import Combine
import Foundation

@MainActor
class DashboardViewModel: ObservableObject {
    @Published var expenses: [Expense] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private var cancellables = Set<AnyCancellable>()

    func fetchExpenses() {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                let fetchedExpenses = try await ExpenseService.shared.fetchExpenses()
                // Sort by date descending
                self.expenses = fetchedExpenses.sorted(by: {
                    ($0.date ?? Date.distantPast) > ($1.date ?? Date.distantPast)
                })
                isLoading = false
            } catch {
                isLoading = false
                errorMessage = "Failed to load expenses: \(error.localizedDescription)"
            }
        }
    }

    func deleteExpense(_ expense: Expense) {
        Task {
            do {
                try await ExpenseService.shared.deleteExpense(expense)
                if let index = expenses.firstIndex(where: { $0.id == expense.id }) {
                    expenses.remove(at: index)
                }
            } catch {
                errorMessage = "Failed to delete expense: \(error.localizedDescription)"
            }
        }
    }

    func deleteAllExpenses() {
        Task {
            do {
                try await ExpenseService.shared.deleteAllExpenses()
                expenses.removeAll()
            } catch {
                errorMessage = "Failed to delete all expenses: \(error.localizedDescription)"
            }
        }
    }
}
