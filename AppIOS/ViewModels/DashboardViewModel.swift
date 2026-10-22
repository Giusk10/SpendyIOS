import Foundation
import Observation

@MainActor
@Observable
final class DashboardViewModel {
    private(set) var expenses: [Expense] = []
    private(set) var income: [Expense] = []
    private(set) var outflows: [Expense] = []
    private(set) var incomeTotal = 0.0
    private(set) var expenseTotal = 0.0
    private(set) var isLoading = false
    private(set) var isMutating = false
    var errorMessage: String?
    private var loadedRevision: Int?
    private var loadTask: Task<Void, Never>?

    func loadIfNeeded() async {
        if loadedRevision != ExpenseService.shared.revision {
            await fetchExpenses()
        }
    }

    func fetchExpenses() async {
        if let loadTask {
            await loadTask.value
            return
        }
        isLoading = true
        errorMessage = nil
        let task = Task {
            defer { isLoading = false }
            do {
                // A mutation can finish while a read is in flight. Discard that stale snapshot.
                repeat {
                    let revision = ExpenseService.shared.revision
                    let fetched = try await ExpenseService.shared.fetchExpenses()
                    guard revision == ExpenseService.shared.revision else { continue }
                    expenses = fetched.sorted { ($0.date ?? .distantPast) > ($1.date ?? .distantPast) }
                    rebuildSummaries()
                    loadedRevision = revision
                } while loadedRevision != ExpenseService.shared.revision
            } catch is CancellationError {
            } catch {
                errorMessage = "Impossibile caricare le transazioni. \(error.localizedDescription)"
            }
        }
        loadTask = task
        await task.value
        loadTask = nil
    }

    func deleteExpense(_ expense: Expense) async {
        guard !isMutating else { return }
        isMutating = true
        errorMessage = nil
        defer { isMutating = false }
        do {
            try await ExpenseService.shared.deleteExpense(expense)
            expenses.removeAll { $0.id == expense.id }
            rebuildSummaries()
            // Leave the revision stale so a simultaneous read cannot restore deleted data.
            loadedRevision = nil
        } catch {
            errorMessage = "Eliminazione non riuscita. \(error.localizedDescription)"
        }
    }

    func deleteAllExpenses() async {
        guard !isMutating else { return }
        isMutating = true
        errorMessage = nil
        defer { isMutating = false }
        do {
            try await ExpenseService.shared.deleteAllExpenses()
            expenses = []
            rebuildSummaries()
            loadedRevision = nil
        } catch {
            errorMessage = "Eliminazione non riuscita. \(error.localizedDescription)"
        }
    }

    private func rebuildSummaries() {
        income = expenses.filter { $0.amount > 0 }
        outflows = expenses.filter { $0.amount < 0 }
        incomeTotal = income.reduce(0) { $0 + $1.amount }
        expenseTotal = outflows.reduce(0) { $0 + $1.amount }
    }
}
