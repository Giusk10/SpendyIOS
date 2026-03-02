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

    @Namespace private var namespace

    var body: some View {
        ZStack {
            // MARK: - Background
            Color.spendyBackground
                .ignoresSafeArea()

            Color.spendyMeshGradient
                .opacity(0.15)
                .ignoresSafeArea()
                .blur(radius: 40)

            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 28) {

                        // 1. Transaction Type Toggle (Top Center)
                        transactionTypeSegmentedControl
                            .padding(.top, 16)

                        // 2. Main Amount Input (Hero)
                        amountSection

                        // 3. Details Form
                        detailsForm
                            .padding(.horizontal, 20)

                        if let error = errorMessage {
                            errorBanner(error)
                                .padding(.horizontal, 20)
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                        }

                        saveButton
                            .padding(.horizontal, 20)
                            .padding(.bottom, 24)
                    }
                    .padding(.vertical, 16)
                }
            }
        }
        .navigationTitle(isExpense ? "Nuova Spesa" : "Nuova Entrata")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .fontWeight(.bold)
                        .foregroundStyle(Color.spendyGradient)
                }
            }

            ToolbarItem(placement: .principal) {
                Text("Nuova Transazione")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.spendyGradient)
            }
        }
        .navigationBarBackButtonHidden(true)
    }

    // MARK: - Components

    private var transactionTypeSegmentedControl: some View {
        ZStack(alignment: .leading) {
            // Track background
            Capsule()
                .fill(Color.spendySurface)
                .shadow(color: Color.spendyShadowNear, radius: 6, x: 0, y: 2)
                .shadow(color: Color.spendyShadowFar, radius: 12, x: 0, y: 4)
                .overlay {
                    Capsule()
                        .stroke(Color.spendyBorderSubtle, lineWidth: 0.5)
                }

            // Animated sliding pill
            GeometryReader { geo in
                let pillWidth = geo.size.width / 2
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                isExpense ? Color.spendyRed : Color.spendyGreen,
                                isExpense ? Color.spendyRed.opacity(0.8) : Color.spendyGreen.opacity(0.8)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: pillWidth - 6)
                    .padding(4)
                    .shadow(
                        color: (isExpense ? Color.spendyRed : Color.spendyGreen).opacity(0.35),
                        radius: 8,
                        x: 0,
                        y: 3
                    )
                    .offset(x: isExpense ? 0 : pillWidth)
                    .animation(.spring(response: 0.35, dampingFraction: 0.72), value: isExpense)
            }

            // Labels row
            HStack(spacing: 0) {
                typeSegmentButton(title: "Uscita", icon: "arrow.up.right", isSelected: isExpense) {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.72)) {
                        isExpense = true
                    }
                }
                typeSegmentButton(title: "Entrata", icon: "arrow.down.left", isSelected: !isExpense) {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.72)) {
                        isExpense = false
                    }
                }
            }
        }
        .frame(height: 50)
        .padding(.horizontal, 20)
    }

    private func typeSegmentButton(
        title: String,
        icon: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .bold))
                Text(title)
                    .font(.system(size: 14, weight: .bold))
            }
            .foregroundColor(isSelected ? .white : .spendySecondaryText)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var amountSection: some View {
        VStack(spacing: 6) {
            Text("IMPORTO")
                .font(.system(size: 11, weight: .bold))
                .tracking(2.5)
                .foregroundColor(.spendyTertiaryText)

            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text("€")
                    .font(.system(size: 28, weight: .semibold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.spendySecondaryText, Color.spendyTertiaryText],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .offset(y: -6)

                TextField("0", text: $amount)
                    .font(.system(size: 72, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        amount.isEmpty
                            ? AnyShapeStyle(Color.spendyTertiaryText.opacity(0.5))
                            : AnyShapeStyle(
                                LinearGradient(
                                    colors: [Color.spendyText, Color.spendyText.opacity(0.85)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    )
                    .multilineTextAlignment(.center)
                    .keyboardType(.decimalPad)
                    .fixedSize(horizontal: true, vertical: false)
                    .tint(.spendyPrimary)
            }
            .padding(.vertical, 4)

            // Subtle underline accent
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.spendyPrimary.opacity(0.5), Color.spendyAccent.opacity(0.3)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: 60, height: 3)
                .opacity(amount.isEmpty ? 0.3 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: amount.isEmpty)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    private var detailsForm: some View {
        VStack(spacing: 16) {
            // Description — SpendyTextField
            SpendyTextField(
                label: "Descrizione (es. Spesa al supermercato)",
                text: $description,
                icon: "pencil.line",
                autocapitalization: .sentences
            )

            // Date & Time in SpendyCard
            SpendyCard(style: .default, padding: 0, cornerRadius: 16) {
                HStack(spacing: 0) {
                    // Date picker side
                    HStack(spacing: 10) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Color.spendyGradientSubtle)
                                .frame(width: 34, height: 34)

                            Image(systemName: "calendar")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(Color.spendyGradient)
                        }

                        DatePicker("", selection: $date, displayedComponents: .date)
                            .labelsHidden()
                            .tint(.spendyPrimary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 14)
                    .padding(.vertical, 14)

                    // Separator
                    Rectangle()
                        .fill(Color.spendyBorderSubtle)
                        .frame(width: 1, height: 32)

                    // Time picker side
                    HStack(spacing: 10) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Color.spendyGradientSubtle)
                                .frame(width: 34, height: 34)

                            Image(systemName: "clock")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(Color.spendyGradient)
                        }

                        DatePicker("", selection: $date, displayedComponents: .hourAndMinute)
                            .labelsHidden()
                            .tint(.spendyPrimary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 14)
                    .padding(.vertical, 14)
                    .padding(.trailing, 14)
                }
            }

            // Payment Method Section
            VStack(alignment: .leading, spacing: 10) {
                Text("METODO DI PAGAMENTO")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(1.5)
                    .foregroundColor(.spendyTertiaryText)
                    .padding(.leading, 4)

                HStack(spacing: 12) {
                    paymentMethodCard(type: "Carta", icon: "creditcard.fill", selected: type == "Carta")
                    paymentMethodCard(type: "Contanti", icon: "banknote.fill", selected: type == "Contanti")
                }
            }
        }
    }

    private func paymentMethodCard(type: String, icon: String, selected: Bool) -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                self.type = type
            }
        }) {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .fill(
                            selected
                                ? LinearGradient(
                                    colors: [Color.spendyPrimary, Color.spendyAccent],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                                : LinearGradient(
                                    colors: [Color.spendyBackgroundDark, Color.spendyBackgroundDark],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                        )
                        .frame(width: 36, height: 36)

                    Image(systemName: icon)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(selected ? .white : .spendySecondaryText)
                }

                Text(type)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(selected ? .spendyPrimary : .spendySecondaryText)

                Spacer()

                if selected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(Color.spendyGradient)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(selected ? Color.spendyPrimary.opacity(0.06) : Color.spendySurface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(
                                selected
                                    ? LinearGradient(
                                        colors: [
                                            Color.spendyPrimaryLight.opacity(0.7),
                                            Color.spendyAccentLight.opacity(0.4)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                    : LinearGradient(
                                        colors: [Color.spendyBorderSubtle, Color.spendyBorderSubtle],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                lineWidth: selected ? 1.5 : 0.5
                            )
                    )
                    .shadow(
                        color: selected ? Color.spendyPrimary.opacity(0.12) : Color.spendyShadowNear,
                        radius: selected ? 10 : 4,
                        x: 0,
                        y: selected ? 4 : 2
                    )
            )
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selected)
        }
        .buttonStyle(.plain)
    }

    private var saveButton: some View {
        SpendyButton(
            "Salva Transazione",
            isLoading: isLoading,
            isDisabled: !canSave,
            leadingIcon: "checkmark.circle.fill"
        ) {
            saveExpense()
        }
    }

    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.spendyRed)

            Text(message)
                .font(.footnote)
                .fontWeight(.medium)
                .foregroundColor(.spendyRed)

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.spendyRedLight)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.spendyRed.opacity(0.3), lineWidth: 1)
        }
    }

    // MARK: - Logic

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
