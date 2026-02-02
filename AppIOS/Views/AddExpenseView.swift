import SwiftUI

struct AddExpenseView: View {
    @Environment(\.dismiss) var dismiss

    @State private var isExpense: Bool = true  // true = Uscita, false = Entrata
    @State private var description: String = ""
    @State private var amount: String = ""
    @State private var date: Date = Date()
    @State private var type: String = "Carta"
    @State private var isLoading = false
    @State private var errorMessage: String?

    let expenseTypes = ["Carta", "Contanti"]

    var body: some View {
        NavigationView {
            ZStack {
                Color.spendyBackground
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {

                        // 1. Amount Card using standard rounded style
                        amountSection

                        // 2. Transaction Type Toggle (Below Amount)
                        transactionTypeSelector

                        // 3. Details and Save
                        VStack(spacing: 24) {
                            detailsSection

                            if let error = errorMessage {
                                errorBanner(error)
                            }

                            saveButton
                        }
                        .padding(.horizontal, 24)
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Components

    private var transactionTypeSelector: some View {
        HStack(spacing: 16) {
            TransactionTypeButton(
                title: "Uscita",
                icon: "arrow.up.right",
                isSelected: isExpense,
                action: { isExpense = true }
            )

            TransactionTypeButton(
                title: "Entrata",
                icon: "arrow.down.left",
                isSelected: !isExpense,
                action: { isExpense = false }
            )
        }
        .padding(.horizontal, 24)
    }

    private var amountSection: some View {
        VStack(spacing: 8) {
            Text("Importo")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.spendySecondaryText)

            HStack(alignment: .center, spacing: 8) {
                Text("€")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundColor(.spendyText)

                TextField("0.00", text: $amount)
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .foregroundColor(.spendyText)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.leading)
                    .fixedSize()
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .background(Color.white)
        .cornerRadius(24)
        .shadow(color: Color.black.opacity(0.03), radius: 15, x: 0, y: 5)
        .padding(.horizontal, 24)
    }

    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 20) {

            // Descrizione
            VStack(alignment: .leading, spacing: 8) {
                Text("Descrizione")
                    .font(.subheadline)
                    .foregroundColor(.spendySecondaryText)

                TextField("Es. Spesa al supermercato", text: $description)
                    .font(.body)
                    .padding(16)
                    .background(Color.spendyBackground)
                    .cornerRadius(12)
            }

            // Data e Ora
            VStack(alignment: .leading, spacing: 8) {
                Text("Data e Ora")
                    .font(.subheadline)
                    .foregroundColor(.spendySecondaryText)

                HStack(spacing: 12) {
                    // Date Part
                    HStack(spacing: 8) {
                        Image(systemName: "calendar")
                            .foregroundColor(.spendyPrimary)
                        DatePicker("", selection: $date, displayedComponents: .date)
                            .datePickerStyle(.compact)
                            .labelsHidden()
                            .accentColor(.spendyPrimary)
                    }

                    Spacer()

                    // Time Part
                    HStack(spacing: 8) {
                        Image(systemName: "clock.fill")
                            .foregroundColor(.spendyPrimary)
                        DatePicker("", selection: $date, displayedComponents: .hourAndMinute)
                            .datePickerStyle(.compact)
                            .labelsHidden()
                            .accentColor(.spendyPrimary)
                    }
                }
                .padding(12)
                .background(Color.spendyBackground)
                .cornerRadius(12)
            }

            // Tipo
            VStack(alignment: .leading, spacing: 8) {
                Text("Metodo")
                    .font(.subheadline)
                    .foregroundColor(.spendySecondaryText)

                HStack {
                    // Dynamic icon based on selection
                    Image(systemName: type == "Carta" ? "creditcard.fill" : "banknote.fill")
                        .foregroundColor(.spendyPrimary)
                        .font(.system(size: 18))

                    Picker("Tipo", selection: $type) {
                        ForEach(expenseTypes, id: \.self) { expenseType in
                            HStack {
                                Text(expenseType)
                            }
                            .tag(expenseType)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(.spendyPrimary)
                    .labelsHidden()

                    Spacer()
                }
                .padding(12)
                .background(Color.spendyBackground)
                .cornerRadius(12)
            }
        }
        .padding(24)
        .background(Color.white)
        .cornerRadius(24)
        .shadow(color: Color.black.opacity(0.03), radius: 15, x: 0, y: 5)
    }

    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
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
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18, weight: .bold))
                    Text(isExpense ? "Salva Uscita" : "Salva Entrata")
                        .font(.headline)
                        .fontWeight(.bold)
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                canSave && !isLoading
                    ? AnyView(Color.spendyGradient)
                    : AnyView(Color.gray.opacity(0.3))
            )
            .cornerRadius(28)
            .shadow(
                color: canSave && !isLoading ? Color.spendyPrimary.opacity(0.3) : Color.clear,
                radius: 10, x: 0, y: 5)
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
        // Logic: Uscita (isExpense) -> Negative, Entrata (!isExpense) -> Positive
        let finalAmount = isExpense ? -abs(amountValue) : abs(amountValue)

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
                    errorMessage = "Errore: \(error.localizedDescription)"
                }
            }
        }
    }
}

// Custom Toggle Button matching Dashboard FilterChip style
struct TransactionTypeButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .bold))
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            .foregroundColor(isSelected ? .white : .spendySecondaryText)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)  // Make buttons expand equally
            .background {
                if isSelected {
                    Capsule()
                        .fill(Color.spendyGradient)
                } else {
                    Capsule()
                        .fill(Color.white)
                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                }
            }
        }
        .buttonStyle(.plain)
    }
}
