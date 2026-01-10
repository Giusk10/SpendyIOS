import SwiftUI

struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()
    @State private var showingDeleteAlert = false
    
    // Computed property for total balance
    var totalBalance: Double {
        viewModel.expenses.reduce(0) { $0 + $1.amount }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.spendyBackground
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header Summary
                    VStack(spacing: 8) {
                        Text("Total Balance")
                            .font(.subheadline)
                            .foregroundColor(.spendySecondaryText)
                        Text(totalBalance, format: .currency(code: "EUR"))
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundColor(totalBalance >= 0 ? .spendyText : .spendyRed)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(Color.white)
                    .overlay(
                        viewModel.isLoading ? ProgressView().frame(maxWidth: .infinity, alignment: .trailing).padding() : nil
                    )
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                    
                    if let errorMessage = viewModel.errorMessage {
                         Text(errorMessage)
                            .foregroundColor(.spendyRed)
                            .font(.caption)
                            .padding()
                    }
                    
                    List {
                        ForEach(viewModel.expenses) { expense in
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
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden) // Fix black background issue
                    .refreshable {
                        viewModel.fetchExpenses()
                    }
                }
            }
            }
            .navigationTitle("Spese")
            .accentColor(.spendyText) // Ensure Dark accent for navigation items
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        AuthManager.shared.logout()
                    }) {
                         HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                            Text("Logout")
                        }
                        .foregroundColor(.spendyRed)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                     HStack {
                        Button(action: {
                            showingDeleteAlert = true
                        }) {
                            Image(systemName: "trash")
                        }
                        .foregroundColor(.spendyRed) // Explicit Red color
                        .disabled(viewModel.expenses.isEmpty)

                        NavigationLink(destination: AddExpenseView()) {
                            Image(systemName: "plus.circle.fill")
                                .symbolRenderingMode(.hierarchical)
                                .font(.title2)
                        }
                    }
                }
            }
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
