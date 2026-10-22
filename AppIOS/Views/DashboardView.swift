import SwiftUI

struct DashboardView: View {
    @Environment(DashboardViewModel.self) private var viewModel
    @ObservedObject private var service = ExpenseService.shared
    @ObservedObject private var authManager = AuthManager.shared
    @State private var showingDeleteAlert = false
    @State private var showingProfile = false
    @State private var selectedFilter: TransactionFilter = .all

    enum TransactionFilter: String, CaseIterable {
        case all = "Tutte"
        case income = "Entrate"
        case expenses = "Uscite"
    }

    private var filteredExpenses: [Expense] {
        switch selectedFilter {
        case .all: viewModel.expenses
        case .income: viewModel.income
        case .expenses: viewModel.outflows
        }
    }

    private var balance: Double {
        switch selectedFilter {
        case .all: viewModel.incomeTotal + viewModel.expenseTotal
        case .income: viewModel.incomeTotal
        case .expenses: viewModel.expenseTotal
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    BalanceSummary(balance: balance, income: viewModel.incomeTotal,
                                   expenses: abs(viewModel.expenseTotal), filter: selectedFilter)
                    TransactionFilters(selection: $selectedFilter)
                    if let error = viewModel.errorMessage {
                        SpendyMessage(message: error)
                        Button("Riprova") { Task { await viewModel.fetchExpenses() } }
                    }
                    if viewModel.isLoading && viewModel.expenses.isEmpty {
                        ProgressView("Caricamento transazioni…")
                            .frame(maxWidth: .infinity).padding(32)
                    } else {
                        VStack(alignment: .leading, spacing: 12) {
                            ViewThatFits(in: .horizontal) {
                                HStack {
                                    Text("Movimenti recenti").font(.headline).accessibilityAddTraits(.isHeader)
                                    Spacer()
                                    NavigationLink("Vedi tutti") { AllExpensesView() }
                                        .font(.subheadline.weight(.semibold))
                                }
                                VStack(alignment: .leading) {
                                    Text("Movimenti recenti").font(.headline).accessibilityAddTraits(.isHeader)
                                    NavigationLink("Vedi tutti") { AllExpensesView() }
                                }
                            }
                            if filteredExpenses.isEmpty {
                                SpendyEmptyState(title: "Nessuna transazione",
                                                 message: "Aggiungi un movimento o importa un file CSV.")
                            } else {
                                SpendyCard(padding: 0) {
                                    VStack(spacing: 0) {
                                        ForEach(filteredExpenses.prefix(4)) { expense in
                                            NavigationLink { ExpenseDetailView(expense: expense) } label: {
                                                ExpenseRow(expense: expense)
                                            }
                                            .buttonStyle(.plain)
                                            if expense.id != filteredExpenses.prefix(4).last?.id {
                                                Divider().padding(.horizontal, 16)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    NavigationLink { UploadView() } label: {
                        SpendyCard {
                            HStack(spacing: 14) {
                                Image(systemName: "doc.badge.plus")
                                    .font(.title2).foregroundStyle(Color.spendyPrimary).accessibilityHidden(true)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Importa transazioni").font(.headline)
                                    Text("Dal file CSV della tua banca")
                                        .font(.subheadline).foregroundStyle(Color.spendySecondaryText)
                                }
                                Spacer(minLength: 0)
                                Image(systemName: "chevron.right").accessibilityHidden(true).font(.caption).foregroundStyle(Color.spendySecondaryText)
                            }
                            .foregroundStyle(Color.spendyText)
                        }
                    }
                    .buttonStyle(.plain)
                }
                .frame(maxWidth: SpendyLayout.contentWidth)
                .padding(SpendyLayout.pagePadding)
                .frame(maxWidth: .infinity)
            }
            .background(Color.spendyBackground)
            .navigationTitle("Spendy")
            .navigationBarTitleDisplayMode(.inline)
            .refreshable { await viewModel.fetchExpenses() }
            .task(id: service.revision) { await viewModel.loadIfNeeded() }
            .task {
                if authManager.currentUser == nil { await authManager.fetchUserProfile() }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Profilo", systemImage: "person.crop.circle") { showingProfile = true }
                }
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Menu {
                        Button("Elimina tutte le transazioni", systemImage: "trash", role: .destructive) {
                            showingDeleteAlert = true
                        }
                        .disabled(viewModel.expenses.isEmpty || viewModel.isMutating || viewModel.isLoading)
                    } label: {
                        Label("Altre azioni", systemImage: "ellipsis")
                    }
                    NavigationLink { AddExpenseView() } label: {
                        Label("Aggiungi transazione", systemImage: "plus")
                    }
                }
            }
            .confirmationDialog("Elimina tutte le transazioni?", isPresented: $showingDeleteAlert,
                                titleVisibility: .visible) {
                Button("Elimina tutte", role: .destructive) {
                    Task { await viewModel.deleteAllExpenses() }
                }
            } message: {
                Text("Questa azione non può essere annullata.")
            }
            .sheet(isPresented: $showingProfile) { UserProfileView() }
        }
    }
}

struct BalanceSummary: View {
    let balance: Double
    let income: Double
    let expenses: Double
    let filter: DashboardView.TransactionFilter
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        SpendyCard(padding: 20) {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Label(filter == .all ? "Saldo totale" : filter.rawValue, systemImage: "wallet.bifold")
                        .font(.subheadline.weight(.medium)).foregroundStyle(Color.spendySecondaryText)
                    Text(balance, format: .currency(code: "EUR"))
                        .font(.largeTitle.bold()).monospacedDigit()
                        .foregroundStyle(Color.spendyPrimary)
                }
                Divider()
                let layout = dynamicTypeSize.isAccessibilitySize
                    ? AnyLayout(VStackLayout(alignment: .leading, spacing: 16))
                    : AnyLayout(HStackLayout(alignment: .top, spacing: 20))
                layout {
                    SummaryAmount(title: "Entrate", amount: income, isIncome: true)
                    SummaryAmount(title: "Uscite", amount: expenses, isIncome: false)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct SummaryAmount: View {
    let title: String
    let amount: Double
    let isIncome: Bool
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: isIncome ? "arrow.down.left" : "arrow.up.right")
                .font(.caption.weight(.medium)).foregroundStyle(Color.spendySecondaryText)
            Text(amount, format: .currency(code: "EUR"))
                .font(.headline).monospacedDigit()
                .foregroundStyle(isIncome ? Color.spendyGreen : Color.spendyRed)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct ExpenseRow: View {
    let expense: Expense
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: CategoryMapper.icon(for: expense.category))
                .font(.body.weight(.medium))
                .foregroundStyle(CategoryMapper.color(for: expense.category))
                .frame(width: 40, height: 40)
                .background(CategoryMapper.color(for: expense.category).opacity(0.10),
                            in: RoundedRectangle(cornerRadius: 12))
                .accessibilityHidden(true)
            let layout = dynamicTypeSize.isAccessibilitySize
                ? AnyLayout(VStackLayout(alignment: .leading, spacing: 8))
                : AnyLayout(HStackLayout(alignment: .top, spacing: 12))
            layout {
                VStack(alignment: .leading, spacing: 4) {
                    Text(expense.userDescription.isEmpty ? "Transazione" : expense.userDescription)
                        .font(.body.weight(.medium)).foregroundStyle(.primary)
                        .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 2)
                    if let date = expense.date {
                        Text(date.formattedDescription(withTime: true))
                            .font(.caption).foregroundStyle(Color.spendySecondaryText)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Text(expense.amount, format: .currency(code: expense.currency ?? "EUR"))
                    .font(.subheadline.weight(.semibold)).monospacedDigit()
                    .foregroundStyle(expense.amount >= 0 ? Color.spendyGreen : Color.spendyText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .accessibilityElement(children: .combine)
    }
}

struct TransactionFilters: View {
    @Binding var selection: DashboardView.TransactionFilter
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(DashboardView.TransactionFilter.allCases, id: \.self) { filter in
                    FilterChip(title: filter.rawValue, isSelected: filter == selection) { selection = filter }
                }
            }
        }
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title).font(.subheadline.weight(.semibold))
                .padding(.horizontal, 18).frame(minHeight: 44)
                .foregroundStyle(isSelected ? Color.white : Color.spendySecondaryText)
                .background(isSelected ? Color.spendyPrimaryDark : Color.spendySurface, in: Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
