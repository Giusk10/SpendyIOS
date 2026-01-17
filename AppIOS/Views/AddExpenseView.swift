import SwiftUI

struct AddExpenseView: View {
    @Environment(\.dismiss) var dismiss
    
    @State private var description: String = ""
    @State private var amount: Double = 0.0
    @State private var date: Date = Date()
    @State private var category: String = "General"
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    // Simple predefined categories
    let categories = ["General", "Food", "Transport", "Shopping", "Entertainment", "Bills", "Health"]

    var body: some View {
        ZStack {
            Color.spendyBackground
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header Card
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Dettagli Spesa")
                            .font(.headline)
                            .foregroundColor(.spendyText)
                        
                        TextField("Descrizione", text: $description)
                            .foregroundColor(.spendyText)
                            .padding()
                            .background(Color.spendyBackground)
                            .cornerRadius(8)
                        
                        TextField("Importo", value: $amount, format: .currency(code: "EUR"))
                            .foregroundColor(.spendyText)
                            .keyboardType(.decimalPad)
                            .padding()
                            .background(Color.spendyBackground)
                            .cornerRadius(8)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Categoria")
                                .font(.subheadline)
                                .foregroundColor(.spendySecondaryText)
                            
                            Picker("Categoria", selection: $category) {
                                ForEach(categories, id: \.self) {
                                    Text($0)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.spendyBackground)
                            .cornerRadius(8)
                        }
                    }
                    .padding(20)
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                    
                    // Date Card
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Data")
                            .font(.headline)
                            .foregroundColor(.spendyText)
                        
                        DatePicker("Seleziona Data", selection: $date, displayedComponents: .date)
                            .datePickerStyle(.graphical)
                            .accentColor(.spendyPrimary)
                    }
                    .padding(20)
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                    
                    if let error = errorMessage {
                         Text(error)
                            .foregroundColor(.spendyRed)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(8)
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Nuova Spesa")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                if isLoading {
                    ProgressView()
                } else {
                    Button("Salva") {
                        saveExpense()
                    }
                    .foregroundColor(.spendyPrimary)
                    .disabled(description.isEmpty || amount == 0)
                }
            }
        }
    }
    
    private func saveExpense() {
        isLoading = true
        errorMessage = nil
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let dateString = formatter.string(from: date)
        
        // Ensure negative amount for expense if user enters positive
        // Though user might enter negative. Let's assume standard is negative.
        // User enters 10 -> -10. User enters -10 -> -10.
        let finalAmount = -abs(amount)
        
        let expense = Expense(
            type: "Manual",
            product: "Manual",
            startedDate: dateString,
            completedDate: dateString,
            userDescription: description,
            amount: finalAmount,
            category: category
        )
        
        Task {
            do {
                try await ExpenseService.shared.addExpense(expense)
                await MainActor.run {
                    isLoading = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Failed to save: \(error.localizedDescription)"
                }
            }
        }
    }
}
