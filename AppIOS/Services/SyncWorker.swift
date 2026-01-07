import Foundation
import SwiftData
import Network

class SyncWorker {
    static let shared = SyncWorker()
    private let networkMonitor = NWPathMonitor()
    private var isConnected = false
    
    private init() {
        networkMonitor.pathUpdateHandler = { path in
            self.isConnected = path.status == .satisfied
            if self.isConnected {
                Task {
                    // Auto-sync when back online
                    // requires context, which we might not have here easily if not passed.
                    // For now, views or service will trigger sync when they can, 
                    // or we can use a notification to let ExpenseService know.
                    NotificationCenter.default.post(name: .connectivityRestored, object: nil)
                }
            }
        }
        networkMonitor.start(queue: DispatchQueue.global())
    }
    
    func sync(context: ModelContext) async {
        guard isConnected else { return }
        
        await pushChanges(context: context)
        await pullChanges(context: context)
        await uploadPendingCSVs()
    }
    
    private func pushChanges(context: ModelContext) async {
        // 1. Pending Add
        // 2. Pending Delete
        let descriptor = FetchDescriptor<Expense>(predicate: #Predicate<Expense> { expense in
            expense.syncStatus != 0
        })
        
        do {
            let pendingExpenses = try context.fetch(descriptor)
            
            for expense in pendingExpenses {
                if expense.syncStatus == 1 { // Pending Add
                    // Post to backend
                    let dto = expense.toDTO()
                    // If we need to exclude ID for new creation or backend ignores it.
                    // Assuming backend adds and returns new object or we just send it.
                    // Spec: POST /addExpense Body compatible with model.
                    if let _ = try? await NetworkManager.shared.performRequest(endpoint: "/Expense/rest/expense/addExpense", method: "POST", body: JSONEncoder().encode(dto), responseType: ExpenseDTO.self) {
                         expense.syncStatus = 0
                        // update remoteId if returned? Assuming for now we rely on Pull to get it or backend doesn't return ID in body but we should refresh.
                        // Ideally we get the ID back.
                    }
                } else if expense.syncStatus == 2 { // Pending Delete
                    if let remoteId = expense.remoteId {
                         let body = ["expenseId": remoteId]
                        if let _ = try? await NetworkManager.shared.performRequest(endpoint: "/Expense/rest/expense/deleteExpense", method: "DELETE", body: JSONSerialization.data(withJSONObject: body), responseType: String.self) { // String or Void
                             context.delete(expense)
                        } else {
                            // If failed, maybe check if 404 then delete local?
                        }
                    } else {
                        // No remote ID, just delete local
                        context.delete(expense)
                    }
                }
            }
            try? context.save()
        } catch {
            print("Push failed: \(error)")
        }
    }
    
    private func pullChanges(context: ModelContext) async {
        // GET /getExpenses
        do {
            let remoteExpenses = try await NetworkManager.shared.performRequest(endpoint: "/Expense/rest/expense/getExpenses", responseType: [ExpenseDTO].self)
            
            // Sync strategy:
            // 1. Get all local expenses
            // 2. Update existing ones with remote data (match by remoteId)
            // 3. Insert new ones
            // 4. (Optional) Delete locals that are not in remote? (Simple sync)
            
            let localDescriptor = FetchDescriptor<Expense>()
            let localExpenses = try context.fetch(localDescriptor)
            
            let remoteIdMap = Dictionary(uniqueKeysWithValues: remoteExpenses.map { ($0.id ?? "", $0) })
            
            for expense in localExpenses {
                guard let rId = expense.remoteId else { continue }
                if let remoteDTO = remoteIdMap[rId] {
                    // Update local
                    if expense.syncStatus == 0 { // Only update if not locally modified pending sync
                        update(expense: expense, with: remoteDTO)
                    }
                } else {
                     // Exists locally (with remoteId) but not on server -> Deleted on server?
                     // Or maybe server returns paged data? Assuming full list for now.
                     // If full list, we should delete local.
                     if expense.syncStatus == 0 {
                         context.delete(expense)
                     }
                }
            }
            
            // Insert new
            let localRemoteIds = Set(localExpenses.compactMap { $0.remoteId })
            for remoteDTO in remoteExpenses {
                if let rId = remoteDTO.id, !localRemoteIds.contains(rId) {
                    let newExpense = remoteDTO.toExpense()
                    newExpense.syncStatus = 0
                    context.insert(newExpense)
                }
            }
            
            try? context.save()
            
        } catch {
             print("Pull failed: \(error)")
        }
    }

    private func update(expense: Expense, with dto: ExpenseDTO) {
        expense.type = dto.type ?? expense.type
        expense.product = dto.product ?? expense.product
        expense.startedDate = dto.startedDate ?? expense.startedDate
        expense.completedDate = dto.completedDate ?? expense.completedDate
        expense.userDescription = dto.description ?? expense.userDescription
        expense.amount = dto.amount ?? expense.amount
        expense.fee = dto.fee ?? expense.fee
        expense.currency = dto.currency ?? expense.currency
        expense.state = dto.state ?? expense.state
        expense.category = dto.category ?? expense.category
    }
    
    // CSV Upload
    func queueCSV(url: URL) {
        let fileManager = FileManager.default
        guard let docs = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let pendingDir = docs.appendingPathComponent("PendingUploads")
        
        try? fileManager.createDirectory(at: pendingDir, withIntermediateDirectories: true)
        
        let destination = pendingDir.appendingPathComponent(url.lastPathComponent)
        try? fileManager.copyItem(at: url, to: destination)
        
        // Try upload immediately
        Task { await uploadPendingCSVs() }
    }
    
    private func uploadPendingCSVs() async {
        let fileManager = FileManager.default
        guard let docs = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let pendingDir = docs.appendingPathComponent("PendingUploads")
        
        guard let files = try? fileManager.contentsOfDirectory(at: pendingDir, includingPropertiesForKeys: nil) else { return }
        
        for fileURL in files {
            do {
                let success = try await NetworkManager.shared.uploadFile(endpoint: "/Expense/rest/expense/import", fileURL: fileURL)
                if success {
                    try? fileManager.removeItem(at: fileURL)
                }
            } catch {
                print("Failed to upload CSV: \(error)")
            }
        }
    }
}

extension Notification.Name {
    static let connectivityRestored = Notification.Name("connectivityRestored")
}
