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

            Color.spendyMeshGradient
                .opacity(0.12)
                .ignoresSafeArea()
                .blur(radius: 40)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    amountHeader
                        .opacity(animateContent ? 1 : 0)
                        .offset(y: animateContent ? 0 : 20)

                    detailsCard
                        .opacity(animateContent ? 1 : 0)
                        .offset(y: animateContent ? 0 : 30)

                    actionButtons
                        .opacity(animateContent ? 1 : 0)
                        .offset(y: animateContent ? 0 : 40)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 48)
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

    // MARK: - Amount Header

    private var amountHeader: some View {
        SpendyCard(style: .elevated, padding: 28, cornerRadius: 24) {
            VStack(spacing: 16) {
                // Category icon in gradient circle
                ZStack {
                    // Outer glow ring
                    Circle()
                        .fill(categoryColor.opacity(0.12))
                        .frame(width: 96, height: 96)

                    // Inner gradient circle
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    categoryColor.opacity(0.22),
                                    categoryColor.opacity(0.10)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 78, height: 78)
                        .overlay {
                            Circle()
                                .stroke(categoryColor.opacity(0.3), lineWidth: 1)
                        }

                    Image(systemName: categoryIcon)
                        .font(.system(size: 34, weight: .semibold))
                        .foregroundColor(categoryColor)
                        .shadow(color: categoryColor.opacity(0.25), radius: 8, x: 0, y: 4)
                }

                VStack(spacing: 8) {
                    // Description — editable or display
                    if isEditing {
                        TextField("Cosa hai comprato?", text: $description)
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(.spendySecondaryText)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                            .tint(.spendyPrimary)
                    } else {
                        Text(description.isEmpty ? "Spesa senza nome" : description.uppercased())
                            .font(.system(size: 12, weight: .bold))
                            .tracking(1.8)
                            .foregroundColor(.spendyTertiaryText)
                    }

                    // Amount — editable or display
                    if isEditing {
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text("€")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(.spendyText)

                            TextField(
                                "0.00",
                                value: Binding(
                                    get: { abs(amount) },
                                    set: { newValue in
                                        if amount < 0 {
                                            amount = -abs(newValue)
                                        } else {
                                            amount = abs(newValue)
                                        }
                                    }
                                ), format: .number.precision(.fractionLength(2))
                            )
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(.spendyText)
                            .keyboardType(.decimalPad)
                            .fixedSize()
                            .tint(.spendyPrimary)
                        }
                    } else {
                        Text(amount, format: .currency(code: expense.currency ?? "EUR"))
                            .font(.system(size: 52, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.spendyText, Color.spendyText.opacity(0.85)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    }

                    // Date — editable or display
                    if isEditing {
                        DatePicker("", selection: $startedDate)
                            .labelsHidden()
                            .colorMultiply(.spendyText)
                            .tint(.spendyPrimary)
                            .scaleEffect(0.9)
                    } else {
                        HStack(spacing: 6) {
                            Image(systemName: "calendar")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.spendyTertiaryText)

                            Text(
                                startedDate.formattedDescription(
                                    withTime: Calendar.current.component(.year, from: startedDate)
                                        == Calendar.current.component(.year, from: Date()))
                            )
                            .font(.system(size: 14, weight: .regular, design: .rounded))
                            .foregroundColor(.spendySecondaryText)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Details Card

    private var detailsCard: some View {
        SpendyCard(style: .default, padding: 0, cornerRadius: 20) {
            VStack(spacing: 0) {
                // Category row (only shown when present)
                if let cat = expense.category {
                    detailRow(
                        icon: "tag.fill",
                        label: "CATEGORIA",
                        iconColor: categoryColor
                    ) {
                        Text(cat)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(categoryColor)
                    }

                    Divider()
                        .padding(.leading, 56)
                        .padding(.trailing, 16)
                }

                // Payment method row
                detailRow(
                    icon: "creditcard.fill",
                    label: "METODO",
                    iconColor: .spendyPrimary
                ) {
                    if isEditing {
                        Picker("", selection: $type) {
                            Text("Carta").tag("Carta")
                            Text("Pagamento con carta").tag("Pagamento con carta")
                            Text("Ricarica").tag("Ricarica")
                            Text("Contanti").tag("Contanti")
                        }
                        .pickerStyle(.menu)
                        .tint(.spendyPrimary)
                        .offset(x: 8)
                    } else {
                        Text(type == "Pagamento con carta" ? "Carta" : type)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.spendyText)
                    }
                }

                // Currency row (only when present)
                if let currency = expense.currency {
                    Divider()
                        .padding(.leading, 56)
                        .padding(.trailing, 16)

                    detailRow(
                        icon: "dollarsign.circle.fill",
                        label: "VALUTA",
                        iconColor: .spendyGreen
                    ) {
                        Text(currency)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.spendyText)
                    }
                }

                // Fee row (only when present and non-zero)
                if let fee = expense.fee, fee != 0 {
                    Divider()
                        .padding(.leading, 56)
                        .padding(.trailing, 16)

                    detailRow(
                        icon: "percent",
                        label: "COMMISSIONE",
                        iconColor: .spendyOrange
                    ) {
                        Text(fee, format: .currency(code: expense.currency ?? "EUR"))
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.spendyOrange)
                    }
                }
            }
        }
    }

    // MARK: - Reusable Detail Row

    private func detailRow<Content: View>(
        icon: String,
        label: String,
        iconColor: Color,
        @ViewBuilder content: () -> Content
    ) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(iconColor.opacity(0.10))
                    .frame(width: 36, height: 36)

                Image(systemName: icon)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(iconColor)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(label)
                    .font(.system(size: 10, weight: .bold))
                    .tracking(1.2)
                    .foregroundColor(.spendyTertiaryText)

                content()
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    // MARK: - Action Buttons

    @ViewBuilder
    private var actionButtons: some View {
        if isEditing {
            SpendyButton(
                "Salva Modifiche",
                variant: .primary,
                leadingIcon: "checkmark.circle.fill"
            ) {
                updateExpense()
            }
            .transition(.opacity.combined(with: .move(edge: .bottom)))
        } else {
            SpendyButton(
                "Elimina transazione",
                variant: .destructive,
                leadingIcon: "trash.fill"
            ) {
                deleteExpense()
            }
            .transition(.opacity.combined(with: .move(edge: .top)))
        }
    }

    // MARK: - Private Logic

    private func initializeFields() {
        description = expense.userDescription
        amount = expense.amount
        category = expense.category ?? ""
        if ["Pagamento con carta", "Carta", "Ricarica", "Contanti"].contains(
            expense.type)
        {
            type = expense.type
        } else if expense.type == "Manuale" {
            type = "Contanti"
        } else {
            type = "Contanti"
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
