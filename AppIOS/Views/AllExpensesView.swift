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
                filterChipsBar
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
                            .tint(.spendyPrimary)
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

    // MARK: - Filter Chips Bar

    private var filterChipsBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
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
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
        }
        .background(Color.spendySurface)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.spendyBorderSubtle)
                .frame(height: 0.5)
        }
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
                .background(Color.spendySurface)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.spendyBorderSubtle, lineWidth: 0.5)
                }
                .shadow(color: Color.spendyShadowFar, radius: 10, x: 0, y: 3)
                .shadow(color: Color.spendyShadowNear, radius: 3, x: 0, y: 1)
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

    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.spendyOrange)

            Text(message)
                .font(.subheadline)
                .foregroundColor(.spendyText)

            Spacer()
        }
        .padding(16)
        .background(Color.spendyOrangeLight)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.spendyOrange.opacity(0.25), lineWidth: 1)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 0) {
            Spacer()

            SpendyCard(style: .gradientBordered, padding: 36, cornerRadius: 24) {
                VStack(spacing: 20) {
                    // Illustration circle
                    ZStack {
                        Circle()
                            .fill(Color.spendyGradientSubtle)
                            .frame(width: 96, height: 96)

                        Circle()
                            .fill(Color.spendyBorderSubtle.opacity(0.5))
                            .frame(width: 80, height: 80)

                        Image(systemName: searchText.isEmpty ? "tray.fill" : "magnifyingglass")
                            .font(.system(size: 36, weight: .medium))
                            .foregroundStyle(Color.spendyGradient)
                    }

                    VStack(spacing: 8) {
                        Text(searchText.isEmpty ? "Nessuna transazione" : "Nessun risultato")
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .foregroundColor(.spendyText)

                        Text(
                            searchText.isEmpty
                                ? "Non ci sono spese da mostrare"
                                : "Prova a cercare qualcos'altro"
                        )
                        .font(.system(size: 14))
                        .foregroundColor(.spendySecondaryText)
                        .multilineTextAlignment(.center)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 32)

            Spacer()
        }
    }
}
