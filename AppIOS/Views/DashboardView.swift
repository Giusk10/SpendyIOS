import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Expense.startedDate, order: .reverse) private var expenses: [Expense]
    
    // Computed property for total balance
    var totalBalance: Double {
        expenses.reduce(0) { $0 + $1.amount }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header Summary
                    VStack(spacing: 8) {
                        Text("Total Balance")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        Text(totalBalance, format: .currency(code: "EUR"))
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundColor(totalBalance >= 0 ? .primary : .red)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(Color(UIColor.systemBackground))
                    
                    List {
                        ForEach(expenses) { expense in
                            ExpenseCard(expense: expense)
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        }
                        .onDelete(perform: deleteItems)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    NavigationLink(destination: UploadView()) {
                        Image(systemName: "square.and.arrow.down")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: AddExpenseView()) {
                        Image(systemName: "plus.circle.fill")
                            .symbolRenderingMode(.hierarchical)
                            .font(.title2)
                    }
                }
            }
            .onAppear {
                 ExpenseService.shared.setModelContext(modelContext)
            }
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(expenses[index])
            }
        }
    }
}

struct ExpenseCard: View {
    let expense: Expense
    
    var body: some View {
        NavigationLink(destination: ExpenseDetailView(expense: expense)) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    // Row 1: Description
                    Text(expense.userDescription)
                        .font(.headline)
                        .lineLimit(2)
                        .foregroundColor(.primary)
                    
                    // Row 2: Date
                    if let date = expense.startedDate {
                        Text(date.formattedDate())
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Row 3: Category
                    if let category = expense.category {
                        Text(category)
                            .font(.caption2)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(8)
                    }
                }
                
                Spacer()
                
                // Right Side: Amount
                Text(expense.amount, format: .currency(code: expense.currency ?? "EUR"))
                    .font(.headline)
                    .foregroundColor(expense.amount >= 0 ? .green : .red)
            }
            .padding()
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle()) // Keeps the custom styling without default link blue
    }
}

extension String {
    func formattedDate() -> String {
        // Quick helper to format string dates nicely if possible
        // Assuming format "yyyy-MM-dd HH:mm:ss" from CSV or AddExpense
        let parser = DateFormatter()
        parser.dateFormat = "yyyy-MM-dd HH:mm:ss"
        if let date = parser.date(from: self) {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return formatter.string(from: date)
        }
        // Fallback for just yyyy-MM-dd
        parser.dateFormat = "yyyy-MM-dd"
        if let date = parser.date(from: self) {
             let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return formatter.string(from: date)
        }
        return self
    }
}
