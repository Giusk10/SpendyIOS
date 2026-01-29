import SwiftUI

struct ExpenseDetailView: View {
    let expense: Expense
    @Environment(\.dismiss) private var dismiss

    @State private var description: String = ""
    @State private var amount: Double = 0.0
    @State private var startedDate: Date = Date()
    @State private var category: String = ""
    @State private var type: String = "EXPENSE"
    @State private var product: String = ""
    @State private var isEditing = false
    @State private var animateContent = false

    var categoryColor: Color {
        CategoryMapper.color(for: expense.category)
    }

    var categoryIcon: String {
        CategoryMapper.icon(for: expense.category)
    }

    var body: some View {
        ZStack {
            Color.spendyBackground
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    amountHeader
                        .opacity(animateContent ? 1 : 0)
                        .offset(y: animateContent ? 0 : 20)

                    detailsCard
                        .opacity(animateContent ? 1 : 0)
                        .offset(y: animateContent ? 0 : 30)

                    if isEditing {
                        saveButton
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }

                    deleteButton
                        .opacity(animateContent ? 1 : 0)
                        .offset(y: animateContent ? 0 : 40)
                }
                .padding(20)
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("Dettaglio")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isEditing.toggle()
                    }
                }) {
                    Image(systemName: isEditing ? "xmark.circle.fill" : "pencil.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(
                            isEditing
                                ? AnyShapeStyle(Color.spendySecondaryText)
                                : AnyShapeStyle(Color.spendyGradient))
                }
            }
        }
        .onAppear {
            initializeFields()
            withAnimation(.easeOut(duration: 0.5)) {
                animateContent = true
            }
        }
    }

    private var amountHeader: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(categoryColor.opacity(0.15))
                    .frame(width: 80, height: 80)

                Image(systemName: categoryIcon)
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundColor(categoryColor)
            }

            if isEditing {
                TextField("Descrizione", text: $description)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.spendyText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            } else {
                Text(description.isEmpty ? "Nessuna descrizione" : description)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.spendyText)
                    .multilineTextAlignment(.center)
            }

            if isEditing {
                HStack(spacing: 4) {
                    Text("€")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(amount >= 0 ? .spendyGreen : .spendyText)

                    TextField("0.00", value: $amount, format: .number.precision(.fractionLength(2)))
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .foregroundColor(amount >= 0 ? .spendyGreen : .spendyText)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.center)
                        .frame(width: 150)
                }
            } else {
                Text(amount, format: .currency(code: expense.currency ?? "EUR"))
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .foregroundColor(amount >= 0 ? .spendyGreen : .spendyText)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .background(Color.white)
        .cornerRadius(24)
        .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
    }

    private var detailsCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Informazioni")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.spendyText)

            DetailRow(label: "Data", icon: "calendar") {
                if isEditing {
                    DatePicker(
                        "", selection: $startedDate, displayedComponents: [.date, .hourAndMinute]
                    )
                    .labelsHidden()
                } else {
                    Text(startedDate.formatted(date: .long, time: .shortened))
                        .fontWeight(.medium)
                        .foregroundColor(.spendyText)
                }
            }

            Divider()

            if let cat = expense.category {
                DetailRow(label: "Categoria", icon: "tag") {
                    HStack(spacing: 8) {
                        Image(systemName: categoryIcon)
                            .font(.system(size: 14))
                        Text(cat)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(categoryColor)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(categoryColor.opacity(0.15))
                    .cornerRadius(8)
                }

                Divider()
            }

            DetailRow(label: "Tipo", icon: "arrow.left.arrow.right") {
                if isEditing {
                    Picker("Tipo", selection: $type) {
                        Text("Pagamento con carta").tag("Pagamento con carta")
                        Text("Ricarica").tag("Ricarica")
                        Text("Manuale").tag("Manuale")
                    }
                    .pickerStyle(.menu)
                    .tint(.spendyPrimary)
                } else {
                    Text(type)
                        .fontWeight(.medium)
                        .foregroundColor(.spendyText)
                }
            }

            if !expense.product.isEmpty {
                Divider()

                DetailRow(label: "Prodotto", icon: "cube.box") {
                    Text(expense.product)
                        .fontWeight(.medium)
                        .foregroundColor(.spendyText)
                        .multilineTextAlignment(.trailing)
                }
            }
        }
        .padding(24)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
    }

    private var saveButton: some View {
        Button(action: updateExpense) {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 20))
                Text("Salva Modifiche")
                    .font(.headline)
                    .fontWeight(.bold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(Color.spendyGradient)
            .cornerRadius(16)
            .shadow(color: Color.spendyPrimary.opacity(0.4), radius: 12, x: 0, y: 6)
        }
    }

    private var deleteButton: some View {
        Button(action: deleteExpense) {
            HStack(spacing: 8) {
                Image(systemName: "trash")
                    .font(.system(size: 16))
                Text("Elimina Spesa")
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.spendyRed)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(Color.spendyRed.opacity(0.1))
            .cornerRadius(14)
        }
    }

    private func initializeFields() {
        description = expense.userDescription
        amount = expense.amount
        category = expense.category ?? ""
        if ["Pagamento con carta", "Ricarica", "Manuale"].contains(expense.type) {
            type = expense.type
        } else {
            type = "Manuale"
        }
        product = expense.product

        if let dateStr = expense.startedDateString {
            startedDate = parseDate(from: dateStr) ?? Date()
        }
    }

    private func parseDate(from string: String) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone.current

        let formats = [
            "yyyy-MM-dd HH:mm:ss",
            "yyyy-MM-dd'T'HH:mm:ss",
            "yyyy-MM-dd'T'HH:mm:ss.SSS",
            "yyyy-MM-dd",
            "dd/MM/yyyy HH:mm:ss",
            "dd/MM/yyyy",
        ]

        for format in formats {
            formatter.dateFormat = format
            if let date = formatter.date(from: string) {
                return date
            }
        }
        return nil
    }

    private func updateExpense() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let dateString = formatter.string(from: startedDate)

        let updatedExpense = Expense(
            id: expense.id,
            type: type,
            product: product,
            startedDate: dateString,
            completedDate: dateString,
            description: description,
            amount: amount,
            fee: expense.fee,
            currency: expense.currency,
            state: expense.state,
            category: category
        )

        Task {
            do {
                try await ExpenseService.shared.updateExpense(updatedExpense)
                dismiss()
            } catch {
                print("Error updating expense: \(error)")
            }
        }
    }

    private func deleteExpense() {
        Task {
            try? await ExpenseService.shared.deleteExpense(expense)
            dismiss()
        }
    }
}

struct DetailRow<Content: View>: View {
    let label: String
    let icon: String
    @ViewBuilder let content: Content

    var body: some View {
        HStack(alignment: .center) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(.spendySecondaryText)
                    .frame(width: 20)

                Text(label)
                    .font(.subheadline)
                    .foregroundColor(.spendySecondaryText)
            }

            Spacer()

            content
        }
    }
}
