import SwiftUI

struct AllExpensesView: View {
    @Environment(DashboardViewModel.self) private var viewModel
    @ObservedObject private var service = ExpenseService.shared
    @State private var searchText = ""
    @State private var selectedFilter: DashboardView.TransactionFilter = .all
    @State private var pendingDeletion: Expense?

    private var filteredExpenses: [Expense] {
        let source: [Expense]
        switch selectedFilter {
        case .all: source = viewModel.expenses
        case .income: source = viewModel.income
        case .expenses: source = viewModel.outflows
        }
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        return query.isEmpty ? source : source.filter {
            $0.userDescription.localizedCaseInsensitiveContains(query)
        }
    }

    var body: some View {
        List {
            Section {
                TransactionFilters(selection: $selectedFilter)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                if let error = viewModel.errorMessage {
                    SpendyMessage(message: error)
                    Button("Riprova") { Task { await viewModel.fetchExpenses() } }
                }
            }
            if viewModel.isLoading && viewModel.expenses.isEmpty {
                ProgressView("Caricamento transazioni…")
            } else if filteredExpenses.isEmpty {
                SpendyEmptyState(title: searchText.isEmpty ? "Nessuna transazione" : "Nessun risultato",
                                 message: "Prova un altro filtro o aggiungi una transazione.")
                    .listRowBackground(Color.clear)
            } else {
                Section {
                    ForEach(filteredExpenses) { expense in
                        NavigationLink { ExpenseDetailView(expense: expense) } label: {
                            ExpenseRow(expense: expense)
                        }
                        .listRowInsets(EdgeInsets())
                        .swipeActions(allowsFullSwipe: false) {
                            Button("Elimina", systemImage: "trash", role: .destructive) {
                                pendingDeletion = expense
                            }
                            .disabled(viewModel.isMutating || viewModel.isLoading)
                        }
                    }
                } header: {
                    Text("\(filteredExpenses.count) movimenti")
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color.spendyBackground)
        .navigationTitle("Transazioni")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: "Cerca una transazione")
        .scrollDismissesKeyboard(.interactively)
        .refreshable { await viewModel.fetchExpenses() }
        .task(id: service.revision) { await viewModel.loadIfNeeded() }
        .confirmationDialog("Eliminare la transazione?", isPresented: Binding(
            get: { pendingDeletion != nil },
            set: { if !$0 { pendingDeletion = nil } }
        ), titleVisibility: .visible) {
            if let expense = pendingDeletion {
                Button("Elimina", role: .destructive) {
                    Task { await viewModel.deleteExpense(expense) }
                    pendingDeletion = nil
                }
            }
        } message: {
            Text("Questa azione non può essere annullata.")
        }
    }
}
