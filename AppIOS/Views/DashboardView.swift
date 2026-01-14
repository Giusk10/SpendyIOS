import SwiftUI

struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()
    @State private var showingDeleteAlert = false
    @State private var searchText = ""
    @FocusState private var isSearchFocused: Bool
    
    enum TransactionFilter: String, CaseIterable {
        case all = "Tutte"
        case income = "Entrate"
        case expenses = "Uscite"
    }
    
    @State private var selectedFilter: TransactionFilter = .all
    
    // Computed property for total balance
    var totalBalance: Double {
        viewModel.expenses.reduce(0) { $0 + $1.amount }
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
        NavigationView {
            ZStack {
                Color.spendyBackground
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Custom Header with Search Bar and Actions
                    HStack(spacing: 12) {
                        
                        if !isSearchFocused {
                            // Logout Button
                            Button(action: {
                                AuthManager.shared.logout()
                            }) {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(width: 44, height: 44)
                                    .background(.ultraThinMaterial, in: Circle())
                            }
                            .transition(.scale.combined(with: .opacity))
                        }

                        // Search Bar
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.spendySecondaryText) // Keep generic secondary text color for icon
                            
                            TextField("Cerca spese...", text: $searchText)
                                .focused($isSearchFocused)
                                .foregroundColor(.white) // Liquid glass usually implies light text on dark or blur
                                .submitLabel(.search)
                            
                            if !searchText.isEmpty || isSearchFocused {
                                Button(action: {
                                    withAnimation(.spring()) {
                                        searchText = ""
                                        isSearchFocused = false
                                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                                    }
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.spendySecondaryText)
                                }
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity) // Allow expansion
                        .background(.ultraThinMaterial, in: Capsule())
                        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2) // Maintain shadow
                        .onTapGesture {
                             isSearchFocused = true
                        }
                        
                        if !isSearchFocused {
                            // Actions (Trash, Add)
                            HStack(spacing: 12) {
                                Button(action: {
                                    showingDeleteAlert = true
                                }) {
                                    Image(systemName: "trash")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(.spendyRed)
                                        .frame(width: 44, height: 44)
                                        .background(.ultraThinMaterial, in: Circle())
                                }
                                .disabled(viewModel.expenses.isEmpty)
                                
                                NavigationLink(destination: AddExpenseView()) {
                                    Image(systemName: "plus")
                                        .font(.system(size: 20, weight: .semibold)) // Standardize size
                                        .foregroundColor(.spendyPrimary)
                                        .frame(width: 44, height: 44)
                                        .background(.ultraThinMaterial, in: Circle())
                                }
                            }
                            .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .animation(.spring(), value: isSearchFocused) // Animate layout changes
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .padding(.bottom, 16)
                    
                    // Header Summary & Filters
                    VStack(spacing: 16) {
                        VStack(spacing: 8) {
                            Text("Total Balance")
                                .font(.subheadline)
                                .foregroundColor(.spendySecondaryText)
                            Text(totalBalance, format: .currency(code: "EUR"))
                                .font(.system(size: 34, weight: .bold, design: .rounded))
                                .foregroundColor(totalBalance >= 0 ? .spendyText : .spendyRed)
                        }
                        
                        // Filter Segmented Control (Restored)
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
                    .overlay(
                        viewModel.isLoading ? ProgressView().frame(maxWidth: .infinity, alignment: .trailing).padding() : nil
                    )
                    
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
                    .scrollContentBackground(.hidden) // Fix black background issue
                    .background(Color.spendyBackground) // Force list background to match app background
                    .refreshable {
                        viewModel.fetchExpenses()
                    }
                }
            }
            .navigationBarHidden(true) // Hide default navigation bar
            .onAppear {
                 viewModel.fetchExpenses()
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

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                viewModel.deleteExpense(viewModel.expenses[index])
            }
        }
    }
}

struct ExpenseCard: View {
    let expense: Expense
    
    var body: some View {
        // Use ZStack to hide default NavigationLink arrow and provide our own
        ZStack {
            NavigationLink(destination: ExpenseDetailView(expense: expense)) {
                EmptyView()
            }
            .opacity(0)
            
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 6) {
                    // Row 1: Description
                    Text(expense.userDescription)
                        .font(.headline)
                        .lineLimit(2)
                        .foregroundColor(.spendyText)
                    
                    // Row 2: Date
                    if let date = expense.startedDate {
                        Text(date.formattedDate())
                            .font(.caption)
                            .foregroundColor(.spendySecondaryText)
                    }
                    
                    // Row 3: Category
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
                
                // Right Side: Amount
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
        // Try the robust formats
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
