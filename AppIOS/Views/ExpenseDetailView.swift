import SwiftUI

struct ExpenseDetailView: View {
    let expense: Expense
    @Environment(\.dismiss) private var dismiss
    @State private var description = ""
    @State private var amountText = ""
    @State private var startedDate = Date()
    @State private var type = ""
    @State private var isEditing = false
    @State private var isLoading = false
    @State private var showingDeleteAlert = false
    @State private var errorMessage: String?
    @State private var initialized = false
    @State private var initialEditingDate = Date()
    @FocusState private var focusedField: Field?
    private enum Field { case description, amount }

    private var canSave: Bool {
        !description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && TransactionInput.amount(from: amountText, allowsZero: true) != nil
    }

    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Label(expense.category ?? "Non classificato",
                          systemImage: CategoryMapper.icon(for: expense.category))
                        .font(.subheadline).foregroundStyle(CategoryMapper.color(for: expense.category))
                    if isEditing {
                        TextField("Descrizione", text: $description, axis: .vertical)
                            .focused($focusedField, equals: .description)
                        TextField("Importo", text: $amountText)
                            .keyboardType(.decimalPad).focused($focusedField, equals: .amount)
                            .accessibilityLabel("Importo in \(expense.currency ?? "EUR")")
                            .font(.largeTitle.bold())
                        Text("Valuta: \(expense.currency ?? "EUR")")
                            .font(.caption).foregroundStyle(Color.spendySecondaryText)
                    } else {
                        Text(expense.userDescription.isEmpty ? "Transazione" : expense.userDescription)
                            .font(.headline)
                        Text(expense.amount, format: .currency(code: expense.currency ?? "EUR"))
                            .font(.largeTitle.bold()).monospacedDigit()
                            .foregroundStyle(expense.amount >= 0 ? Color.spendyGreen : Color.spendyText)
                    }
                }
                .padding(.vertical, 12)
            }
            Section("Dettagli") {
                if isEditing {
                    DatePicker("Data e ora", selection: $startedDate)
                    Picker("Metodo", selection: $type) {
                        if !["Carta", "Pagamento con carta", "Ricarica", "Contanti"].contains(expense.type) {
                            Text(expense.type).tag(expense.type)
                        }
                        Text("Carta").tag("Carta")
                        Text("Pagamento con carta").tag("Pagamento con carta")
                        Text("Ricarica").tag("Ricarica")
                        Text("Contanti").tag("Contanti")
                    }
                } else {
                    LabeledContent("Data", value: expense.date?.formattedDescription(withTime: true)
                                   ?? expense.startedDateString ?? "Non disponibile")
                    LabeledContent("Metodo", value: expense.type)
                }
                if let currency = expense.currency {
                    LabeledContent("Valuta", value: currency)
                }
                if let fee = expense.fee, fee != 0 {
                    LabeledContent("Commissione") {
                        Text(fee, format: .currency(code: expense.currency ?? "EUR"))
                    }
                }
            }
            if let errorMessage {
                Section { SpendyMessage(message: errorMessage) }
                    .listRowInsets(EdgeInsets()).listRowBackground(Color.clear)
            }
            Section {
                if isEditing {
                    SpendyButton("Salva modifiche", isLoading: isLoading, isDisabled: !canSave,
                                 leadingIcon: "checkmark") { updateExpense() }
                } else {
                    SpendyButton("Elimina transazione", variant: .destructive, isLoading: isLoading,
                                 leadingIcon: "trash") { showingDeleteAlert = true }
                }
            }
            .listRowInsets(EdgeInsets()).listRowBackground(Color.clear)
        }
        .disabled(isLoading)
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle("Transazione")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(isEditing ? "Annulla" : "Modifica") {
                    initializeFields()
                    errorMessage = nil
                    focusedField = nil
                    isEditing.toggle()
                }
                .disabled(isLoading)
            }
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Fine") { focusedField = nil }
            }
        }
        .onAppear {
            if !initialized {
                initializeFields()
                initialized = true
            }
        }
        .confirmationDialog("Eliminare la transazione?", isPresented: $showingDeleteAlert,
                            titleVisibility: .visible) {
            Button("Elimina", role: .destructive) { deleteExpense() }
        } message: { Text("Questa azione non può essere annullata.") }
    }

    private func initializeFields() {
        description = expense.userDescription
        amountText = String(abs(expense.amount))
        startedDate = expense.date ?? Date()
        initialEditingDate = startedDate
        type = expense.type
    }

    private func updateExpense() {
        guard !isLoading, canSave, let value = TransactionInput.amount(from: amountText, allowsZero: true) else { return }
        focusedField = nil
        isLoading = true
        errorMessage = nil
        // Keep unedited backend fields byte-for-byte, including the completion timestamp and type.
        let dateChanged = startedDate != initialEditingDate
        let updated = Expense(
            id: expense.id, type: type, product: expense.product,
            startedDate: dateChanged ? TransactionInput.backendDate(startedDate) : expense.startedDateString,
            completedDate: expense.completedDateString, description: description,
            amount: expense.amount < 0 ? -value : value,
            fee: expense.fee, currency: expense.currency, state: expense.state, category: expense.category)
        Task {
            defer { isLoading = false }
            do {
                try await ExpenseService.shared.updateExpense(updated)
                dismiss()
            } catch {
                errorMessage = "Salvataggio non riuscito. \(error.localizedDescription)"
            }
        }
    }

    private func deleteExpense() {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        Task {
            defer { isLoading = false }
            do {
                try await ExpenseService.shared.deleteExpense(expense)
                dismiss()
            } catch {
                errorMessage = "Eliminazione non riuscita. \(error.localizedDescription)"
            }
        }
    }
}
