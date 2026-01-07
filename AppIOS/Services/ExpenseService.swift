import Foundation
import SwiftData

@MainActor
class ExpenseService {
    static let shared = ExpenseService()
    var modelContext: ModelContext?
    
    private init() {
        // Listen for connectivity restored to trigger sync
        NotificationCenter.default.addObserver(self, selector: #selector(triggerSync), name: .connectivityRestored, object: nil)
    }
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }
    
    @objc func triggerSync() {
        guard let context = modelContext else { return }
        Task {
            await SyncWorker.shared.sync(context: context)
        }
    }
    
    func fetchExpenses() throws -> [Expense] {
        guard let context = modelContext else { return [] }
        
        // Trigger sync in background logic
        Task {
            await SyncWorker.shared.sync(context: context)
        }
        
        // Return local data immediately (Offline-First)
        // Filter out those marked for deletion if we want to hide them immediately?
        // Or show them? Usually we hide them.
        let descriptor = FetchDescriptor<Expense>(
            predicate: #Predicate<Expense> { $0.syncStatus != 2 },
            sortBy: [SortDescriptor(\.startedDate, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }
    
    func addExpense(_ expense: Expense) {
        guard let context = modelContext else { return }
        expense.syncStatus = 1 // Pending Add
        context.insert(expense)
        try? context.save()
        
        Task {
            await SyncWorker.shared.sync(context: context)
        }
    }
    
    func deleteExpense(_ expense: Expense) {
        guard let context = modelContext else { return }
        
        if expense.remoteId == nil {
            // If not on server yet, just delete locally
            context.delete(expense)
        } else {
            expense.syncStatus = 2 // Pending Delete
        }
        
        try? context.save()
        Task {
            await SyncWorker.shared.sync(context: context)
        }
    }
    
    // Updated: Just queues the file
    func importCSV(url: URL) throws {
        SyncWorker.shared.queueCSV(url: url)
    }
    
    func deleteAllExpenses() throws {
        guard let context = modelContext else { return }
        // Logic for delete all? Maybe iterate and mark all as deleted?
        // Or call specific endpoint if available?
        // Spec says: DELETE /Expense/rest/expense/deleteExpense (Single)
        // Implementing bulk delete via single deletes or just locally clearing for now?
        // Given complexity, let's just mark visible ones as deleted.
        let all = try fetchExpenses()
        for expense in all {
            deleteExpense(expense) // This handles syncStatus
        }
    }
    
    // Stats logic - fetch from backend if possible, or calculate locally?
    // Spec: POST /Expense/rest/expense/getMonthlyAmountOfYear
    // DashboardView: "Se possibile, integra la chiamata statistiche per i grafici."
    // We can add a method to get stats.
    
    func getMonthlyStats(year: String) async -> [Double]? {
        // This is a direct API call, usually we don't sync stats?
        // If offline, maybe return nil or local calculation?
        // Let's implement local calculation as fallback, but try network first.
        
        if let response = try? await NetworkManager.shared.performRequest(endpoint: "/Expense/rest/expense/getMonthlyAmountOfYear", method: "POST", body: JSONEncoder().encode(["year": year]), responseType: [Double].self) {
            return response
        }
        return nil
    }
}
