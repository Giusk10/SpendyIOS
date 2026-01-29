import SwiftUI

struct AllExpensesView: View {
    @StateObject private var viewModel = DashboardViewModel()

    // MARK: - Local State
    @State private var searchText = ""
    @State private var selectedFilter: DashboardView.TransactionFilter = .all

    // Cache per evitare di ricalcolare i filtri ad ogni frame
    @State private var cachedFilteredExpenses: [Expense] = []

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.spendyBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Filtri Superiori
                filterChips
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.white)
                    .zIndex(1)

                // Banner Errori
                if let errorMessage = viewModel.errorMessage {
                    errorBanner(errorMessage)
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                        .transition(.opacity)
                }

                // Lista o Empty State
                if cachedFilteredExpenses.isEmpty && !viewModel.expenses.isEmpty
                    && searchText.isEmpty
                {
                    if selectedFilter != .all {
                        emptyState
                    } else {
                        ProgressView()
                            .padding(.top, 50)
                    }
                } else if cachedFilteredExpenses.isEmpty {
                    emptyState
                } else {
                    expenseList
                }
            }
        }
        .navigationTitle("Tutte le spese")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(
            text: $searchText,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: "Cerca spese"
        )
        // MARK: - Reactive Logic
        .onAppear {
            viewModel.fetchExpenses()
            applyFilters()
        }
        // SINTASSI iOS 17+ AGGIORNATA
        .onChange(of: searchText) { _, _ in applyFilters() }
        .onChange(of: selectedFilter) { _, _ in applyFilters() }
        .onChange(of: viewModel.expenses) { _, _ in applyFilters() }
    }

    // MARK: - Optimized List
    private var expenseList: some View {
        List {
            ForEach(cachedFilteredExpenses) { expense in
                ZStack {
                    NavigationLink(destination: ExpenseDetailView(expense: expense)) {
                        EmptyView()
                    }
                    .opacity(0)

                    ExpenseRow(expense: expense)
                }
                .padding(.vertical, 4)
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 6, leading: 20, bottom: 6, trailing: 20))
                .listRowSeparator(.hidden)
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        deleteExpense(expense)
                    } label: {
                        Label("Elimina", systemImage: "trash")
                    }
                    .tint(.spendyRed)
                }
            }
        }
        .listStyle(.plain)
        .background(Color.spendyBackground)
        .scrollContentBackground(.hidden)
        .refreshable {
            viewModel.fetchExpenses()
        }
    }

    // MARK: - Logic Helpers
    private func applyFilters() {
        let expenses = viewModel.expenses
        var result: [Expense]

        switch selectedFilter {
        case .all:
            result = expenses
        case .income:
            result = expenses.filter { $0.amount > 0 }
        case .expenses:
            result = expenses.filter { $0.amount < 0 }
        }

        if !searchText.isEmpty {
            result = result.filter {
                $0.userDescription.localizedCaseInsensitiveContains(searchText)
            }
        }

        result.sort { expense1, expense2 in
            let date1 = expense1.date ?? Date.distantPast
            let date2 = expense2.date ?? Date.distantPast
            return date1 > date2
        }

        withAnimation(.easeInOut(duration: 0.2)) {
            self.cachedFilteredExpenses = result
        }
    }

    private func deleteExpense(_ expense: Expense) {
        if let index = cachedFilteredExpenses.firstIndex(of: expense) {
            withAnimation {
                // FIX: Scartiamo il risultato restituito da remove(at:) per evitare il warning
                _ = cachedFilteredExpenses.remove(at: index)
            }
        }
        viewModel.deleteExpense(expense)
    }

    // MARK: - Subviews
    private var filterChips: some View {
        HStack(spacing: 10) {
            ForEach(DashboardView.TransactionFilter.allCases, id: \.self) { filter in
                FilterChip(
                    title: filter.rawValue,
                    isSelected: selectedFilter == filter,
                    action: {
                        selectedFilter = filter
                    }
                )
            }
            Spacer()
        }
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

    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.spendyPrimary.opacity(0.1))
                    .frame(width: 100, height: 100)

                Image(systemName: "magnifyingglass")
                    .font(.system(size: 40))
                    .foregroundStyle(Color.spendyGradient)
            }

            VStack(spacing: 8) {
                Text("Nessun risultato")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.spendyText)

                Text(
                    searchText.isEmpty
                        ? "Non ci sono spese da mostrare" : "Prova a cercare qualcos'altro"
                )
                .font(.subheadline)
                .foregroundColor(.spendySecondaryText)
            }

            Spacer()
        }
    }
}
