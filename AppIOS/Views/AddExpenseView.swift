import SwiftUI

struct AddExpenseView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isExpense = true
    @State private var description = ""
    @State private var amount = ""
    @State private var date = Date()
    @State private var type = "Carta"
    @State private var isLoading = false
    @State private var errorMessage: String?
    @FocusState private var focusedField: Field?
    private enum Field { case amount, description }

    private var parsedAmount: Double? { TransactionInput.amount(from: amount) }
    private var canSave: Bool {
        !description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && parsedAmount != nil
    }

    var body: some View {
        Form {
            Section {
                Picker("Movimento", selection: $isExpense) {
                    Text("Uscita").tag(true)
                    Text("Entrata").tag(false)
                }
                .pickerStyle(.segmented)
                VStack(alignment: .leading, spacing: 8) {
                    Text("Importo in EUR").font(.subheadline).foregroundStyle(Color.spendySecondaryText)
                    TextField("0,00", text: $amount)
                        .font(.largeTitle.bold()).monospacedDigit()
                        .keyboardType(.decimalPad)
                        .focused($focusedField, equals: .amount)
                        .accessibilityLabel("Importo in euro")
                }
                .padding(.vertical, 12)
            }
            Section("Dettagli") {
                TextField("Descrizione", text: $description, axis: .vertical)
                    .focused($focusedField, equals: .description)
                    .submitLabel(.done)
                DatePicker("Data", selection: $date, displayedComponents: .date)
                DatePicker("Ora", selection: $date, displayedComponents: .hourAndMinute)
                Picker("Metodo di pagamento", selection: $type) {
                    Text("Carta").tag("Carta")
                    Text("Contanti").tag("Contanti")
                }
            }
            if let errorMessage {
                Section { SpendyMessage(message: errorMessage) }
                    .listRowInsets(EdgeInsets()).listRowBackground(Color.clear)
            }
            Section {
                SpendyButton("Salva transazione", isLoading: isLoading, isDisabled: !canSave,
                             leadingIcon: "checkmark") { saveExpense() }
                    .listRowInsets(EdgeInsets()).listRowBackground(Color.clear)
            }
        }
        .disabled(isLoading)
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle(isExpense ? "Nuova spesa" : "Nuova entrata")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Fine") { focusedField = nil }
            }
        }
    }

    private func saveExpense() {
        guard canSave, !isLoading, let amountValue = parsedAmount else { return }
        focusedField = nil
        isLoading = true
        errorMessage = nil
        let dateString = TransactionInput.backendDate(date)
        let expense = Expense(type: type, product: "Manual",
                              startedDate: dateString, completedDate: dateString,
                              description: description,
                              amount: isExpense ? -amountValue : amountValue, category: nil)
        Task {
            defer { isLoading = false }
            do {
                try await ExpenseService.shared.addExpense(expense)
                dismiss()
            } catch {
                errorMessage = "Salvataggio non riuscito. \(error.localizedDescription)"
            }
        }
    }
}

#Preview("Nuova spesa • Light") {
    NavigationStack { AddExpenseView() }.preferredColorScheme(.light)
}
#Preview("Nuova spesa • Dark") {
    NavigationStack { AddExpenseView() }.preferredColorScheme(.dark)
}
