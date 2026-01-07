import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var expenseViewModel = ExpenseViewModel()
    
    var body: some View {
        NavigationView {
            List {
                if expenseViewModel.isLoading {
                    ProgressView()
                } else if let error = expenseViewModel.errorMessage {
                    Text(error).foregroundColor(.red)
                } else {
                    ForEach(expenseViewModel.expenses) { expense in
                        VStack(alignment: .leading) {
                            Text(expense.description)
                                .font(.headline)
                            HStack {
                                Text(expense.amount, format: .currency(code: expense.currency ?? "EUR"))
                                Spacer()
                                Text(expense.state ?? "")
                                    .font(.caption)
                                    .padding(4)
                                    .background(Color.gray.opacity(0.2))
                                    .cornerRadius(4)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Dashboard")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Logout") {
                        authViewModel.logout()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: UploadView()) {
                        Image(systemName: "square.and.arrow.down")
                    }
                }
            }
            .onAppear {
                expenseViewModel.loadExpenses()
            }
        }
    }
}
