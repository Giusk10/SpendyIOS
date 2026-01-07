import SwiftUI

struct ExpenseDetailView: View {
    let expense: Expense
    
    var body: some View {
        Form {
            Section(header: Text("Details")) {
                HStack {
                    Text("Description")
                    Spacer()
                    Text(expense.userDescription)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Amount")
                    Spacer()
                    Text(expense.amount, format: .currency(code: expense.currency ?? "EUR"))
                        .foregroundColor(expense.amount >= 0 ? .green : .red)
                        .bold()
                }
                
                HStack {
                    Text("Date")
                    Spacer()
                    if let date = expense.startedDate {
                        Text(date)
                            .foregroundColor(.secondary)
                    }
                }
                
                HStack {
                    Text("Category")
                    Spacer()
                    if let category = expense.category {
                        Text(category)
                            .padding(4)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(4)
                    }
                }
                
                HStack {
                    Text("Type")
                    Spacer()
                    Text(expense.type)
                        .foregroundColor(.secondary)
                }
                
                if !expense.product.isEmpty {
                    HStack {
                        Text("Product")
                        Spacer()
                        Text(expense.product)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section {
                    Button(action: deleteExpense) {
                        Text("Delete Expense")
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
            }
        }
        .navigationTitle("Expense Details")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    @Environment(\.dismiss) private var dismiss
    
    private func deleteExpense() {
        ExpenseService.shared.deleteExpense(expense)
        dismiss()
    }
}
