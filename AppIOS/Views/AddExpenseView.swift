import SwiftUI

struct AddExpenseView: View {
    @Environment(\.dismiss) var dismiss

    @State private var description: String = ""
    @State private var amount: String = ""
    @State private var date: Date = Date()
    @State private var type: String = "Pagamento con carta"
    @State private var isLoading = false
    @State private var errorMessage: String?

    let expenseTypes = ["Pagamento con carta", "Ricarica", "Bonifico", "Prelievo"]

    var body: some View {
        ZStack {
            Color.spendyBackground
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    amountCard

                    detailsCard

                    if let error = errorMessage {
                        errorBanner(error)
                    }

                    saveButton
                }
                .padding(20)
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("Nuova Spesa")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var amountCard: some View {
        VStack(spacing: 16) {
            Text("Importo")
                .font(.subheadline)
                .foregroundColor(.spendySecondaryText)

            HStack(alignment: .center, spacing: 4) {
                Text("€")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.spendyText)

                TextField("0.00", text: $amount)
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(.spendyText)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.center)
                    .frame(minWidth: 100)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .background(Color.white)
        .cornerRadius(24)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.spendySecondaryText.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
    }

    private var detailsCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Dettagli")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.spendyText)

            VStack(alignment: .leading, spacing: 8) {
                Text("Descrizione")
                    .font(.subheadline)
                    .foregroundColor(.spendySecondaryText)

                TextField("Es. Spesa al supermercato", text: $description)
                    .padding(16)
                    .background(Color.spendyBackground)
                    .cornerRadius(12)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Data e Ora")
                    .font(.subheadline)
                    .foregroundColor(.spendySecondaryText)

                DatePicker("", selection: $date, displayedComponents: [.date, .hourAndMinute])
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .padding(12)
                    .background(Color.spendyBackground)
                    .cornerRadius(12)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Tipo")
                    .font(.subheadline)
                    .foregroundColor(.spendySecondaryText)

                Picker("Tipo", selection: $type) {
                    ForEach(expenseTypes, id: \.self) { expenseType in
                        Text(expenseType).tag(expenseType)
                    }
                }
                .pickerStyle(.menu)
                .tint(.spendyPrimary)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.spendyBackground)
                .cornerRadius(12)
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.spendySecondaryText.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
    }

    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundColor(.spendyRed)
            Text(message)
                .font(.subheadline)
                .foregroundColor(.spendyRed)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.spendyRed.opacity(0.1))
        .cornerRadius(12)
    }

    private var saveButton: some View {
        Button(action: saveExpense) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        canSave
                            ? Color.spendyGradient
                            : LinearGradient(
                                colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.2)],
                                startPoint: .leading, endPoint: .trailing)
                    )
                    .shadow(
                        color: canSave ? Color.spendyPrimary.opacity(0.4) : Color.clear, radius: 12,
                        x: 0, y: 6)

                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20))
                        Text("Salva Spesa")
                            .font(.headline)
                            .fontWeight(.bold)
                    }
                    .foregroundColor(.white)
                }
            }
            .frame(height: 56)
        }
        .disabled(!canSave || isLoading)
    }

    private var canSave: Bool {
        !description.isEmpty && !amount.isEmpty
            && (Double(amount.replacingOccurrences(of: ",", with: ".")) ?? 0) > 0
    }

    private func saveExpense() {
        isLoading = true
        errorMessage = nil

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let dateString = formatter.string(from: date)

        let amountValue = Double(amount.replacingOccurrences(of: ",", with: ".")) ?? 0
        let finalAmount = -abs(amountValue)

        let expense = Expense(
            type: type,
            product: "Manual",
            startedDate: dateString,
            completedDate: dateString,
            description: description,
            amount: finalAmount,
            category: nil
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
                    errorMessage = "Errore nel salvataggio: \(error.localizedDescription)"
                }
            }
        }
    }
}
