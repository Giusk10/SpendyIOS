import SwiftUI

struct AllExpensesView: View {
    @StateObject private var viewModel = DashboardViewModel()
    @State private var searchText = ""
    @State private var selectedFilter: DashboardView.TransactionFilter = .all
    @Environment(\.dismiss) private var dismiss
    
    var filteredExpenses: [Expense] {
        let expenses = viewModel.expenses
        let filteredByType: [Expense]
        
        switch selectedFilter {
        case .all:
            filteredByType = expenses
        case .income:
            filteredByType = expenses.filter { $0.amount > 0 }
        case .expenses:
            filteredByType = expenses.filter { $0.amount < 0 }
        }
        
        if searchText.isEmpty {
            return filteredByType
        } else {
            return filteredByType.filter { $0.userDescription.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var groupedExpenses: [(String, [Expense])] {
        let grouped = Dictionary(grouping: filteredExpenses) { expense -> String in
            guard let dateStr = expense.startedDate else { return "Altro" }
            return dateStr.groupDateKey()
        }
        return grouped.sorted { $0.key > $1.key }
    }
    
    var body: some View {
        ZStack {
            Color.spendyBackground
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                filterChips
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.white)
                
                if let errorMessage = viewModel.errorMessage {
                    errorBanner(errorMessage)
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                }
                
                if filteredExpenses.isEmpty {
                    emptyState
                } else {
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 16, pinnedViews: [.sectionHeaders]) {
                            ForEach(groupedExpenses, id: \.0) { section, expenses in
                                Section {
                                    VStack(spacing: 0) {
                                        ForEach(Array(expenses.enumerated()), id: \.element.id) { index, expense in
                                            NavigationLink(destination: ExpenseDetailView(expense: expense)) {
                                                ExpenseRow(expense: expense)
                                            }
                                            .buttonStyle(.plain)
                                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                                Button(role: .destructive) {
                                                    withAnimation {
                                                        viewModel.deleteExpense(expense)
                                                    }
                                                } label: {
                                                    Label("Elimina", systemImage: "trash")
                                                }
                                                .tint(.spendyRed)
                                            }
                                            
                                            if index < expenses.count - 1 {
                                                Divider()
                                                    .padding(.leading, 60)
                                            }
                                        }
                                    }
                                    .background(Color.white)
                                    .cornerRadius(16)
                                    .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
                                    .padding(.horizontal, 20)
                                } header: {
                                    HStack {
                                        Text(section)
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.spendySecondaryText)
                                        Spacer()
                                    }
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 8)
                                    .background(Color.spendyBackground)
                                }
                            }
                        }
                        .padding(.top, 8)
                        .padding(.bottom, 60)
                    }
                    .refreshable {
                        viewModel.fetchExpenses()
                    }
                }
            }
        }
        .navigationTitle("Tutte le spese")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Cerca spese")
        .onAppear {
            viewModel.fetchExpenses()
        }
    }
    
    private var filterChips: some View {
        HStack(spacing: 10) {
            ForEach(DashboardView.TransactionFilter.allCases, id: \.self) { filter in
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
                
                Text(searchText.isEmpty ? "Non ci sono spese da mostrare" : "Prova a cercare qualcos'altro")
                    .font(.subheadline)
                    .foregroundColor(.spendySecondaryText)
            }
            
            Spacer()
        }
    }
}

extension String {
    func groupDateKey() -> String {
        let parser = DateFormatter()
        parser.locale = Locale(identifier: "en_US_POSIX")
        let formats = [
            "yyyy-MM-dd'T'HH:mm:ss.SSSZ",
            "yyyy-MM-dd'T'HH:mm:ssZ",
            "yyyy-MM-dd'T'HH:mm:ss",
            "yyyy-MM-dd HH:mm:ss",
            "yyyy-MM-dd",
            "dd/MM/yyyy",
            "dd-MM-yyyy"
        ]
        
        for format in formats {
            parser.dateFormat = format
            if let date = parser.date(from: self) {
                let calendar = Calendar.current
                
                if calendar.isDateInToday(date) {
                    return "Oggi"
                } else if calendar.isDateInYesterday(date) {
                    return "Ieri"
                } else if calendar.isDate(date, equalTo: Date(), toGranularity: .weekOfYear) {
                    return "Questa settimana"
                } else if calendar.isDate(date, equalTo: Date(), toGranularity: .month) {
                    return "Questo mese"
                } else {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "MMMM yyyy"
                    formatter.locale = Locale(identifier: "it_IT")
                    return formatter.string(from: date).capitalized
                }
            }
        }
        return "Altro"
    }
}
