import SwiftUI
import SwiftData

@main
struct AppIOSApp: App {
    @StateObject private var authManager = AuthManager.shared
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Expense.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            if authManager.isAuthenticated {
                ContentView()
                    .onAppear {
                        // Pass model context to Service
                        let context = sharedModelContainer.mainContext
                        ExpenseService.shared.setModelContext(context)
                    }
            } else {
                AuthView()
            }
        }
        .modelContainer(sharedModelContainer)
    }
}
