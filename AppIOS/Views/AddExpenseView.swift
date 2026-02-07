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
        NavigationStack {
            ZStack {
                // MARK: - Background
                Color.spendyBackground
                    .ignoresSafeArea()

                // Mesh Gradient Overlay for premium feel
                Color.spendyMeshGradient
                    .opacity(0.15)
                    .ignoresSafeArea()
                    .blur(radius: 40)

                VStack(spacing: 0) {
                    // MARK: - Header
                    headerView
                        .padding(.top, 10)

                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 32) {

                            // 1. Transaction Type Toggle (Top Center)
                            transactionTypeSegmentedControl
                                .padding(.top, 10)

                            // 2. Main Amount Input (Hero)
                            amountSection

                            // 3. Details Form
                            detailsForm
                                .padding(.horizontal, 24)

                            // Filler for scroll
                            if let error = errorMessage {
                                errorBanner(error)
                                    .transition(.move(edge: .bottom).combined(with: .opacity))
                            }

                            saveButton
                                .padding(.bottom, 20)
                        }
                        .padding(.vertical, 20)
                    }
                }

            }
            .navigationBarHidden(true)
        }
    }

    // MARK: - Components

    private var headerView: some View {
        HStack(spacing: 16) {
            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 8)
    }

    private var transactionTypeSegmentedControl: some View {
        HStack(spacing: 0) {
            typeSegmentButton(title: "Uscita", isSelected: isExpense) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isExpense = true

                }
            }

            typeSegmentButton(title: "Entrata", isSelected: !isExpense) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isExpense = false

                }
            }
        }
        .padding(4)
        .background(Color.white)
        .clipShape(Capsule())
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
    }

    private func typeSegmentButton(title: String, isSelected: Bool, action: @escaping () -> Void)
        -> some View
    {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .bold : .medium)
                .foregroundColor(isSelected ? .white : .spendySecondaryText)
                .frame(width: 100, height: 36)
                .background {
                    if isSelected {
                        Capsule()
                            .fill(Color.spendyGradient)
                            .matchedGeometryEffect(id: "ActiveTab", in: namespace)
                    }
                }
        }
    }

    @Namespace private var namespace

    private var amountSection: some View {
        VStack(spacing: 8) {
            Text("IMPORTO")
                .font(.caption)
                .fontWeight(.bold)
                .tracking(2)
                .foregroundColor(.spendyTertiaryText)

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("€")
                    .font(.system(size: 32, weight: .medium, design: .rounded))
                    .foregroundColor(.spendySecondaryText)
                    .offset(y: -4)

                TextField("0", text: $amount)
                    .font(.system(size: 64, weight: .bold, design: .rounded))
                    .foregroundColor(.spendyText)
                    .multilineTextAlignment(.center)
                    .keyboardType(.decimalPad)
                    .fixedSize(horizontal: true, vertical: false)
                    .accentColor(.spendyPrimary)
            }
            .padding(.vertical, 10)
        }
        .frame(maxWidth: .infinity)
    }

    private var detailsForm: some View {
        VStack(spacing: 20) {
            // Description Input
            HStack(spacing: 16) {
                Image(systemName: "pencil")
                    .font(.system(size: 18))
                    .foregroundColor(.spendyPrimary)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 4) {
                    if !description.isEmpty {
                        Text("Descrizione")
                            .font(.caption2)
                            .foregroundColor(.spendySecondaryText)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                    TextField("Descrizione (es. Spesa)", text: $description)
                        .font(.body)
                }
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.02), radius: 8, x: 0, y: 2)

            // Date & Time Unified Rectangle
            HStack(spacing: 0) {
                // Date
                HStack(spacing: 8) {
                    Image(systemName: "calendar")
                        .foregroundColor(.spendyAccent)
                    DatePicker("", selection: $date, displayedComponents: .date)
                        .labelsHidden()
                        .accentColor(.spendyPrimary)
                }

                Spacer()

                Divider()
                    .frame(height: 24)
                    .padding(.horizontal, 8)

                Spacer()

                // Time
                HStack(spacing: 8) {
                    Image(systemName: "clock")
                        .foregroundColor(.spendyAccent)
                    DatePicker("", selection: $date, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                        .accentColor(.spendyPrimary)
                }
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.02), radius: 8, x: 0, y: 2)

            // Payment Method
            VStack(alignment: .leading, spacing: 12) {
                Text("METODO DI PAGAMENTO")
                    .font(.caption)
                    .fontWeight(.bold)
                    .tracking(1)
                    .foregroundColor(.spendySecondaryText)
                    .padding(.leading, 4)

                HStack(spacing: 12) {
                    paymentMethodCard(
                        type: "Carta", icon: "creditcard.fill", selected: type == "Carta")
                    paymentMethodCard(
                        type: "Contanti", icon: "banknote.fill", selected: type == "Contanti")
                }
            }
        }
    }

    private func paymentMethodCard(type: String, icon: String, selected: Bool) -> some View {
        Button(action: {
            withAnimation {
                self.type = type
            }
        }) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16))
                Text(type)
                    .font(.subheadline)
                    .fontWeight(.medium)

                if selected {
                    Spacer()
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.spendyPrimary)
                }
            }
            .foregroundColor(selected ? .spendyPrimary : .spendySecondaryText)
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(selected ? Color.spendyPrimary.opacity(0.08) : Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(selected ? Color.spendyPrimary : Color.clear, lineWidth: 1.5)
                    )
            )
            .shadow(color: selected ? .clear : Color.black.opacity(0.02), radius: 5)
        }
    }

    private var saveButton: some View {
        Button(action: saveExpense) {
            HStack {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text("Salva Transazione")
                        .font(.headline)
                        .fontWeight(.bold)
                    Image(systemName: "arrow.right")
                        .fontWeight(.bold)
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                canSave ? AnyView(Color.spendyGradient) : AnyView(Color.gray.opacity(0.3))
            )
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(
                color: canSave ? Color.spendyPrimary.opacity(0.4) : Color.clear, radius: 15, x: 0,
                y: 8
            )
            .scaleEffect(isLoading ? 0.98 : 1)
        }
        .padding(.horizontal, 24)
        .disabled(!canSave || isLoading)
    }

    private func errorBanner(_ message: String) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
            Text(message)
                .font(.footnote)
                .fontWeight(.medium)
        }
        .foregroundColor(.white)
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.spendyRed)
        .cornerRadius(12)
        .shadow(color: Color.spendyRed.opacity(0.3), radius: 10)
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
