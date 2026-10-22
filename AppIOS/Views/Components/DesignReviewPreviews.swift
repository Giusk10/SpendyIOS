import SwiftUI

#if DEBUG
private enum DesignReviewData {
    static let expense = Expense(
        id: "preview-expense", type: "Carta", product: "Card",
        startedDate: "2026-10-22 12:30:00", completedDate: "2026-10-23 09:00:00",
        description: "Spesa al supermercato", amount: -42.50,
        currency: "EUR", category: "Supermercati e Alimentari")
}

private struct FinanceOverviewPreview: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    BalanceSummary(balance: 1240.50, income: 1800, expenses: 559.50, filter: .all)
                    TransactionFilters(selection: .constant(.all))
                    Text("Movimenti recenti").font(.headline).accessibilityAddTraits(.isHeader)
                    SpendyCard(padding: 0) {
                        ExpenseRow(expense: DesignReviewData.expense)
                    }
                    CategoryRow(
                        category: .init(name: "Supermercati e Alimentari", amount: 248.5, count: 8),
                        maxAmount: 350)
                    SpendyMessage(message: "Connessione non disponibile. Riprova.")
                    SpendyButton("Aggiungi transazione", leadingIcon: "plus") {}
                }
                .padding(20)
            }
            .background(Color.spendyBackground)
            .navigationTitle("Spendy").navigationBarTitleDisplayMode(.inline)
        }
        .tint(.spendyPrimary)
    }
}

#Preview("Riepilogo • Light") {
    FinanceOverviewPreview().preferredColorScheme(.light)
}
#Preview("Riepilogo • Dark") {
    FinanceOverviewPreview().preferredColorScheme(.dark)
}
#Preview("Riepilogo • Accessibilità") {
    FinanceOverviewPreview().preferredColorScheme(.dark).dynamicTypeSize(.accessibility3)
}
#Preview("Dettaglio • Light") {
    NavigationStack { ExpenseDetailView(expense: DesignReviewData.expense) }
        .preferredColorScheme(.light).tint(.spendyPrimary)
}
#Preview("Dettaglio • Dark") {
    NavigationStack { ExpenseDetailView(expense: DesignReviewData.expense) }
        .preferredColorScheme(.dark).tint(.spendyPrimary)
}
#endif
