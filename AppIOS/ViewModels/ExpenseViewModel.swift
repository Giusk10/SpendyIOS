import Foundation
import Combine

class ExpenseViewModel: ObservableObject {
    @Published var expenses: [Expense] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    func loadExpenses() {
        isLoading = true
        Task {
            do {
                let fetched = try await ExpenseService.shared.fetchExpenses()
                DispatchQueue.main.async {
                    self.expenses = fetched
                    self.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
}
