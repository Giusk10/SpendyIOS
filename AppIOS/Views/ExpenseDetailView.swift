import SwiftUI

struct ExpenseDetailView: View {
    let expense: Expense
    
    var body: some View {
    var body: some View {
        ZStack {
            Color.spendyBackground
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 20) {
                        // Header info
                        Text(expense.userDescription)
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.spendyText)
                            .multilineTextAlignment(.center)
                        
                        Text(expense.amount, format: .currency(code: expense.currency ?? "EUR"))
                            .font(.system(size: 40, weight: .bold, design: .rounded))
                            .foregroundColor(expense.amount >= 0 ? .spendyGreen : .spendyText)
                        
                        Divider()
                        
                        // Details Grid
                        VStack(spacing: 16) {
                            DetailRow(label: "Data", value: expense.startedDate ?? "-")
                            
                            if let category = expense.category {
                                HStack {
                                    Text("Categoria")
                                        .foregroundColor(.spendySecondaryText)
                                    Spacer()
                                    Text(category)
                                        .fontWeight(.medium)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 4)
                                        .background(Color.spendyPrimary.opacity(0.1))
                                        .foregroundColor(.spendyPrimary)
                                        .cornerRadius(8)
                                }
                            }
                            
                            DetailRow(label: "Tipo", value: expense.type)
                            if !expense.product.isEmpty {
                                DetailRow(label: "Prodotto", value: expense.product)
                            }
                        }
                    }
                    .padding(24)
                    .background(Color.white)
                    .cornerRadius(20)
                    .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                    
                    Button(action: deleteExpense) {
                        HStack {
                            Image(systemName: "trash")
                            Text("Elimina Spesa")
                        }
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.spendyRed)
                        .cornerRadius(12)
                        .shadow(color: Color.spendyRed.opacity(0.3), radius: 5, x: 0, y: 3)
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Dettaglio")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    struct DetailRow: View {
        let label: String
        let value: String
        
        var body: some View {
            HStack {
                Text(label)
                    .foregroundColor(.spendySecondaryText)
                Spacer()
                Text(value)
                    .fontWeight(.medium)
                    .foregroundColor(.spendyText)
            }
        }
    }
    
    @Environment(\.dismiss) private var dismiss
    
    private func deleteExpense() {
        Task {
            try? await ExpenseService.shared.deleteExpense(expense)
            dismiss()
        }
    }
}
