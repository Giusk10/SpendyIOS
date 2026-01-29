import SwiftUI

struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()
    @State private var showingDeleteAlert = false

    enum TransactionFilter: String, CaseIterable {
        case all = "Tutte"
        case income = "Entrate"
        case expenses = "Uscite"
    }

    @State private var selectedFilter: TransactionFilter = .all

    var totalBalance: Double {
        let expensesToSum: [Expense]
        switch selectedFilter {
        case .all:
            expensesToSum = viewModel.expenses
        case .income:
            expensesToSum = viewModel.expenses.filter { $0.amount > 0 }
        case .expenses:
            expensesToSum = viewModel.expenses.filter { $0.amount < 0 }
        }
        return expensesToSum.reduce(0) { $0 + $1.amount }
    }

    var filteredExpenses: [Expense] {
        let expenses = viewModel.expenses
        switch selectedFilter {
        case .all:
            return expenses
        case .income:
            return expenses.filter { $0.amount > 0 }
        case .expenses:
            return expenses.filter { $0.amount < 0 }
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.spendyBackground
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        balanceCard
                        filterSection

                        if let errorMessage = viewModel.errorMessage {
                            errorBanner(errorMessage)
                        }

                        recentTransactionsSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    .padding(.bottom, 60)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                viewModel.fetchExpenses()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        AuthManager.shared.logout()
                    }) {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(Color.spendySecondaryText)
                    }
                }

                ToolbarItem(placement: .principal) {
                    Text("Spendy")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.spendyGradient)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 12) {
                        Button(action: {
                            showingDeleteAlert = true
                        }) {
                            Image(systemName: "trash")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(
                                    .spendyRed.opacity(viewModel.expenses.isEmpty ? 0.4 : 1))
                        }
                        .disabled(viewModel.expenses.isEmpty)

                        NavigationLink(destination: AddExpenseView()) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 24))
                                .foregroundStyle(Color.spendyGradient)
                        }
                    }
                }
            }
        }
        .alert("Elimina tutte le spese", isPresented: $showingDeleteAlert) {
            Button("Annulla", role: .cancel) {}
            Button("Elimina", role: .destructive) {
                viewModel.deleteAllExpenses()
            }
        } message: {
            Text(
                "Sei sicuro di voler eliminare tutte le spese? Questa azione non può essere annullata."
            )
        }
    }

    private var balanceCard: some View {
        VStack(spacing: 0) {
            ZStack {
                RoundedRectangle(cornerRadius: 28)
                    .fill(
                        LinearGradient(
                            colors: [Color.spendyPrimary, Color.spendyAccent],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: Color.spendyPrimary.opacity(0.4), radius: 20, x: 0, y: 10)

                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 200)
                    .offset(x: 100, y: -50)

                Circle()
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 150)
                    .offset(x: -120, y: 60)

                VStack(spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Saldo Totale")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.white.opacity(0.85))

                            Text(totalBalance, format: .currency(code: "EUR"))
                                .font(.system(size: 38, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .contentTransition(.numericText())
                        }
                        Spacer()

                        Circle()
                            .fill(.ultraThinMaterial)
                            .frame(width: 50, height: 50)
                            .overlay {
                                Image(
                                    systemName: totalBalance >= 0
                                        ? "arrow.up.right" : "arrow.down.right"
                                )
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)
                            }
                    }

                    HStack(spacing: 16) {
                        StatItem(
                            title: "Entrate",
                            value: viewModel.expenses.filter { $0.amount > 0 }.reduce(0) {
                                $0 + $1.amount
                            },
                            icon: "arrow.down.left",
                            positive: true
                        )

                        Divider()
                            .frame(height: 40)
                            .background(Color.white.opacity(0.3))

                        StatItem(
                            title: "Uscite",
                            value: abs(
                                viewModel.expenses.filter { $0.amount < 0 }.reduce(0) {
                                    $0 + $1.amount
                                }),
                            icon: "arrow.up.right",
                            positive: false
                        )
                    }
                    .padding(.top, 8)
                }
                .padding(24)
            }
            .frame(height: 200)
        }
    }

    private var filterSection: some View {
        HStack(spacing: 10) {
            ForEach(TransactionFilter.allCases, id: \.self) { filter in
                FilterChip(
                    title: filter.rawValue,
                    isSelected: selectedFilter == filter,
                    action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedFilter = filter
                        }
                    }
                )
            }
        }
        .padding(.vertical, 4)
    }

    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.spendyOrange)
            Text(message)
                .font(.subheadline)
                .foregroundColor(.spendyText)
            Spacer()
        }
        .padding()
        .background(Color.spendyOrange.opacity(0.1))
        .cornerRadius(12)
    }

    private var recentTransactionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Transazioni Recenti")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.spendyText)

                Spacer()

                NavigationLink(destination: AllExpensesView()) {
                    HStack(spacing: 4) {
                        Text("Vedi tutte")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Image(systemName: "chevron.right")
                            .font(.caption)
                    }
                    .foregroundStyle(Color.spendyGradient)
                }
            }

            if filteredExpenses.isEmpty {
                emptyStateView
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(filteredExpenses.prefix(5).enumerated()), id: \.element.id) {
                        index, expense in
                        NavigationLink(destination: ExpenseDetailView(expense: expense)) {
                            ExpenseRow(expense: expense)
                        }
                        .buttonStyle(.plain)

                        if index < min(4, filteredExpenses.count - 1) {
                            Divider()
                                .padding(.leading, 60)
                        }
                    }
                }
                .background(Color.white)
                .cornerRadius(20)
                .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "tray")
                .font(.system(size: 48))
                .foregroundStyle(Color.spendyGradient)

            Text("Nessuna transazione")
                .font(.headline)
                .foregroundColor(.spendyText)

            Text("Aggiungi la tua prima spesa\nper iniziare a monitorare")
                .font(.subheadline)
                .foregroundColor(.spendySecondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
    }
}

struct StatItem: View {
    let title: String
    let value: Double
    let icon: String
    let positive: Bool

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white.opacity(0.7))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                Text(value, format: .currency(code: "EUR"))
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(isSelected ? .white : .spendySecondaryText)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background {
                    if isSelected {
                        Capsule()
                            .fill(Color.spendyGradient)
                            .shadow(color: Color.spendyPrimary.opacity(0.3), radius: 8, x: 0, y: 4)
                    } else {
                        Capsule()
                            .fill(Color.white)
                            .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
                    }
                }
        }
        .buttonStyle(.plain)
    }
}

struct ExpenseRow: View {
    let expense: Expense

    var categoryColor: Color {
        CategoryMapper.color(for: expense.category)
    }

    var categoryIcon: String {
        CategoryMapper.icon(for: expense.category)
    }

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(categoryColor.opacity(0.15))
                    .frame(width: 46, height: 46)

                Image(systemName: categoryIcon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(categoryColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(expense.userDescription)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.spendyText)
                    .lineLimit(1)

                if let date = expense.startedDate {
                    Text(date.formattedDateWithTime())
                        .font(.caption)
                        .foregroundColor(.spendySecondaryText)
                }
            }

            Spacer()

            Text(expense.amount, format: .currency(code: expense.currency ?? "EUR"))
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(expense.amount >= 0 ? .spendyGreen : .spendyText)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

struct ExpenseCard: View {
    let expense: Expense

    var body: some View {
        ZStack {
            NavigationLink(destination: ExpenseDetailView(expense: expense)) {
                EmptyView()
            }
            .opacity(0)

            ExpenseRow(expense: expense)
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
        }
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect, byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

extension String {
    func formattedDate() -> String {
        let parser = DateFormatter()
        parser.locale = Locale(identifier: "en_US_POSIX")
        let formats = [
            "yyyy-MM-dd'T'HH:mm:ss.SSSZ",
            "yyyy-MM-dd'T'HH:mm:ssZ",
            "yyyy-MM-dd'T'HH:mm:ss",
            "yyyy-MM-dd HH:mm:ss",
            "yyyy-MM-dd",
            "dd/MM/yyyy",
            "dd-MM-yyyy",
        ]

        for format in formats {
            parser.dateFormat = format
            if let date = parser.date(from: self) {
                let calendar = Calendar.current
                let timeFormatter = DateFormatter()
                timeFormatter.dateFormat = "HH:mm"

                if calendar.isDateInToday(date) {
                    return "Oggi, \(timeFormatter.string(from: date))"
                } else if calendar.isDateInYesterday(date) {
                    return "Ieri, \(timeFormatter.string(from: date))"
                } else {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "dd MMM"
                    formatter.locale = Locale(identifier: "it_IT")
                    return formatter.string(from: date)
                }
            }
        }
        return self
    }

    func formattedDateWithTime() -> String {
        let parser = DateFormatter()
        parser.locale = Locale(identifier: "en_US_POSIX")
        let formats = [
            "yyyy-MM-dd'T'HH:mm:ss.SSSZ",
            "yyyy-MM-dd'T'HH:mm:ssZ",
            "yyyy-MM-dd'T'HH:mm:ss",
            "yyyy-MM-dd HH:mm:ss",
            "yyyy-MM-dd",
            "dd/MM/yyyy",
            "dd-MM-yyyy",
        ]

        for format in formats {
            parser.dateFormat = format
            if let date = parser.date(from: self) {
                let calendar = Calendar.current
                let timeFormatter = DateFormatter()
                timeFormatter.dateFormat = "HH:mm"
                let timeString = timeFormatter.string(from: date)

                if calendar.isDateInToday(date) {
                    return "Oggi, \(timeString)"
                } else if calendar.isDateInYesterday(date) {
                    return "Ieri, \(timeString)"
                } else {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "dd MMM yyyy, HH:mm"
                    formatter.locale = Locale(identifier: "it_IT")
                    return formatter.string(from: date)
                }
            }
        }
        return self
    }
}
