import SwiftUI

struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()
    @State private var showingDeleteAlert = false
    @State private var searchText = ""
    
    // @FocusState non ha bisogno di essere inizializzata a false, lo è di default.
    // Il problema era l'area di tocco.
    @FocusState private var isSearchFocused: Bool
    
    enum TransactionFilter: String, CaseIterable {
        case all = "Tutte"
        case income = "Entrate"
        case expenses = "Uscite"
    }
    
    @State private var selectedFilter: TransactionFilter = .all
    
    // MARK: - Computed Properties
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
    
    var body: some View {
        // GeometryReader fondamentale per calcolare la larghezza esatta disponibile
        GeometryReader { geometry in
            NavigationView {
                ZStack {
                    Color.spendyBackground
                        .ignoresSafeArea()
                    
                    VStack(spacing: 0) {
                        
                        // --- SOMMARIO SALDO & FILTRI ---
                        VStack(spacing: 16) {
                            VStack(spacing: 8) {
                                Text("Total Balance")
                                    .font(.subheadline)
                                    .foregroundColor(.spendySecondaryText)
                                Text(totalBalance, format: .currency(code: "EUR"))
                                    .font(.system(size: 34, weight: .bold, design: .rounded))
                                    .foregroundColor(totalBalance >= 0 ? .spendyText : .spendyRed)
                            }
                            
                            Picker("Filtro", selection: $selectedFilter) {
                                ForEach(TransactionFilter.allCases, id: \.self) { filter in
                                    Text(filter.rawValue).tag(filter)
                                }
                            }
                            .pickerStyle(.segmented)
                            .padding(.horizontal)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(Color.white)
                        .cornerRadius(20, corners: [.bottomLeft, .bottomRight])
                        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                        .zIndex(1)

                        if let errorMessage = viewModel.errorMessage {
                             Text(errorMessage)
                                .foregroundColor(.spendyRed)
                                .font(.caption)
                                .padding()
                        }
                        
                        List {
                            ForEach(filteredExpenses) { expense in
                                ExpenseCard(expense: expense)
                                    .listRowSeparator(.hidden)
                                    .listRowBackground(Color.clear)
                                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                        Button(role: .destructive) {
                                            viewModel.deleteExpense(expense)
                                        } label: {
                                            Label("Elimina", systemImage: "trash")
                                        }
                                        .tint(.spendyRed)
                                    }
                            }
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                        .refreshable {
                            viewModel.fetchExpenses()
                        }
                    }
                }
                .navigationBarTitleDisplayMode(.inline)
                .onAppear {
                     viewModel.fetchExpenses()
                }
                // MARK: - TOOLBAR REVOLUT STYLE
                .toolbar {
                    
                    // 1. SINISTRA: Profilo (Scompare se cerchi)
                    ToolbarItem(placement: .navigationBarLeading) {
                        if !isSearchFocused {
                            Button(action: {
                                AuthManager.shared.logout()
                            }) {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.primary)
                            }
                            .transition(.opacity)
                        }
                    }
                    
                    // 2. CENTRO: Barra Ricerca
                    ToolbarItem(placement: .principal) {
                        ZStack {
                            // 1. SFONDO: Stesso identico stile/colore dei bottoni laterali
                            Capsule()
                                .fill(Color(uiColor: .secondarySystemBackground)) 
                                .frame(height: 40)
                            
                            // 2. CONTENUTO: Lente, Testo, X
                            HStack(spacing: 0) {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(.gray)
                                    .font(.system(size: 17))
                                    .padding(.leading, 12)
                                
                                TextField("Cerca", text: $searchText)
                                    .focused($isSearchFocused)
                                    .font(.system(size: 17))
                                    .padding(.horizontal, 8)
                                    .frame(height: 40)
                                    .submitLabel(.search)
                                
                                if !searchText.isEmpty {
                                    Button(action: { searchText = "" }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.gray)
                                            .font(.system(size: 17))
                                    }
                                    .padding(.trailing, 10)
                                }
                            }
                            
                            // 3. LAYER INVISIBILE PER IL CLICK (Fondamentale)
                            // Se la tastiera è chiusa, questo rettangolo invisibile cattura il tocco ovunque
                            if !isSearchFocused {
                                Color.clear
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        isSearchFocused = true
                                    }
                            }
                        }
                        // CALCOLO LARGHEZZA
                        // - Espanso: schermo meno margini (32)
                        // - Chiuso: schermo meno spazio bottoni (170)
                        .frame(width: isSearchFocused ? (geometry.size.width - 32) : (geometry.size.width - 170))
                        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: isSearchFocused)
                    }
                    
                    // 3. DESTRA: Bottoni (Scompaiono se cerchi)
                    ToolbarItem(placement: .navigationBarTrailing) {
                        HStack(spacing: 8) {
                            if isSearchFocused {
                                // Bottone ANNULLA
                                Button("Annulla") {
                                    withAnimation {
                                        // Chiude tutto
                                        isSearchFocused = false
                                        searchText = ""
                                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                                    }
                                }
                                .foregroundColor(.blue)
                            } else {
                                // Bottone Cestino
                                Button(action: {
                                    showingDeleteAlert = true
                                }) {
                                    Image(systemName: "trash")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.red)
                                }
                                .disabled(viewModel.expenses.isEmpty)
                                
                                // Bottone Aggiungi (+)
                                NavigationLink(destination: AddExpenseView()) {
                                    Image(systemName: "plus")
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        // Transizione fluida per far sparire/apparire i bottoni
                        .transition(.opacity)
                    }
                }
            }
        }
        .alert("Delete All Expenses", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                viewModel.deleteAllExpenses()
            }
        } message: {
            Text("Are you sure you want to delete all expenses? This action cannot be undone.")
        }
    }
}

// MARK: - Subviews & Extensions

struct ExpenseCard: View {
    let expense: Expense
    
    var body: some View {
        ZStack {
            NavigationLink(destination: ExpenseDetailView(expense: expense)) {
                EmptyView()
            }
            .opacity(0)
            
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(expense.userDescription)
                        .font(.headline)
                        .lineLimit(2)
                        .foregroundColor(.spendyText)
                    
                    if let date = expense.startedDate {
                        Text(date.formattedDate())
                            .font(.caption)
                            .foregroundColor(.spendySecondaryText)
                    }
                    
                    if let category = expense.category {
                        Text(category)
                            .font(.caption2)
                            .fontWeight(.medium)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.spendyPrimary.opacity(0.1))
                            .foregroundColor(.spendyPrimary)
                            .cornerRadius(6)
                    }
                }
                
                Spacer()
                
                Text(expense.amount, format: .currency(code: expense.currency ?? "EUR"))
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(expense.amount >= 0 ? .spendyGreen : .spendyText)
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
        }
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
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
            "dd-MM-yyyy"
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
                    formatter.dateFormat = "dd MMMM yyyy, HH:mm"
                    formatter.locale = Locale(identifier: "it_IT")
                    return formatter.string(from: date)
                }
            }
        }
        return self
    }
}