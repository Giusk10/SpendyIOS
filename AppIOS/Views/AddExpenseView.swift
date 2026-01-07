import SwiftUI
import SwiftData

struct AddExpenseView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var description: String = ""
    @State private var amount: Double = 0.0
    @State private var date: Date = Date()
    @State private var category: String = "General"
    
    // Simple predefined categories
    let categories = ["General", "Food", "Transport", "Shopping", "Entertainment", "Bills", "Health"]

    var body: some View {
        Form {
            Section(header: Text("Details")) {
                TextField("Description", text: $description)
                
                TextField("Amount", value: $amount, format: .currency(code: "EUR"))
                    .keyboardType(.decimalPad)
                
                Picker("Category", selection: $category) {
                    ForEach(categories, id: \.self) {
                        Text($0)
                    }
                }
            }
            
            Section(header: Text("Date")) {
                DatePicker("Date", selection: $date, displayedComponents: .date)
            }
        }
        .navigationTitle("New Expense")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    saveExpense()
                }
                .disabled(description.isEmpty || amount == 0)
            }
        }
        .onAppear {
             // Ensure service context is set if we were to use it helper methods, 
             // though here we might just insert directly or use service.
             ExpenseService.shared.setModelContext(modelContext)
        }
    }
    
    private func saveExpense() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let dateString = formatter.string(from: date)
        
        let expense = Expense(
            type: "Manual",
            product: "Manual",
            startedDate: dateString,
            completedDate: dateString,
            description: description,
            amount: -abs(amount), // Assuming expenses are negative like in CSV
            category: category
        )
        
        // Using Service to be consistent with architecture
        ExpenseService.shared.addExpense(expense)
        
        // Save context
        try? modelContext.save()
        
        dismiss()
    }
}
