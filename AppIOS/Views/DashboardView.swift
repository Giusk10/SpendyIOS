//
//  DashboardView.swift
//  Spendy
//
//  Created by User on 20/09/23.
//

import SwiftUI

// ---------------------------------------------------------
// 2. VIEW PRINCIPALE
// ---------------------------------------------------------

struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()
    @ObservedObject private var authManager = AuthManager.shared

    @State private var showingDeleteAlert = false
    @State private var showingProfile = false
    @State private var selectedFilter: TransactionFilter = .all

    enum TransactionFilter: String, CaseIterable {
        case all = "Tutte"
        case income = "Entrate"
        case expenses = "Uscite"
    }

    // Nota: Idealmente questi calcoli dovrebbero stare nel ViewModel ed essere variabili @Published
    // per evitare di ricalcolare ad ogni render della view.
    var filteredExpenses: [Expense] {
        switch selectedFilter {
        case .all: return viewModel.expenses
        case .income: return viewModel.expenses.filter { $0.amount > 0 }
        case .expenses: return viewModel.expenses.filter { $0.amount < 0 }
        }
    }

    var totalBalance: Double {
        filteredExpenses.reduce(0) { $0 + $1.amount }
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.spendyBackground
                    .ignoresSafeArea()

                if viewModel.isLoading && viewModel.expenses.isEmpty {
                    ScrollView(showsIndicators: false) {
                        SkeletonDashboard()
                            .padding(.top, 10)
                    }
                } else {
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 20) {
                            balanceCard
                                .padding(.top, 10)

                            filterSection

                            if let errorMessage = viewModel.errorMessage {
                                errorBanner(errorMessage)
                            }

                            recentTransactionsSection

                            uploadSection
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 100)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            // Usa .task invece di .onAppear per concorrenza automatica
            .task {
                viewModel.fetchExpenses()
                await AuthManager.shared.fetchUserProfile()
            }
            .toolbar {
                leadingToolbarItem
                principalToolbarItem
                trailingToolbarItem
            }
        }
        .alert("Elimina tutte le spese", isPresented: $showingDeleteAlert) {
            Button("Annulla", role: .cancel) {}
            Button("Elimina", role: .destructive) {
                viewModel.deleteAllExpenses()
            }
        } message: {
            Text(
                "Sei sicuro di voler eliminare tutte le spese? Questa azione non può essere annullata."
            )
        }
        .sheet(isPresented: $showingProfile) {
            UserProfileView()
        }
    }

    // MARK: - Componenti UI Estratti

    private var balanceCard: some View {
        ZStack(alignment: .topTrailing) {
            // Rich deep gradient background
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color.spendyGradientDeep)

            // Decorative orbs layered inside the card
            decorativeOrbs

            // Gradient border overlay
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.25),
                            Color.white.opacity(0.05)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )

            VStack(spacing: 20) {
                // Top row: balance + trend icon
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Saldo Totale")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white.opacity(0.75))
                            .tracking(0.5)

                        Text(totalBalance, format: .currency(code: "EUR"))
                            .font(.system(size: 38, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .contentTransition(.numericText())
                            .shadow(
                                color: Color.spendyAccentDeep.opacity(0.4),
                                radius: 8,
                                x: 0,
                                y: 4
                            )
                    }

                    Spacer()

                    trendIcon
                }

                // Stats row: income + expenses as individual cards
                balanceStatsRow
            }
            .padding(24)
        }
        .frame(height: 210)
        .shadow(color: Color.spendyShadowPrimary, radius: 24, x: 0, y: 10)
        .shadow(color: Color.spendyShadowFar, radius: 8, x: 0, y: 2)
        // Disegna il contenuto come una bitmap off-screen (GPU acceleration)
        .drawingGroup()
    }

    private var decorativeOrbs: some View {
        ZStack {
            // Large orb top-right
            Circle()
                .fill(Color.white.opacity(0.07))
                .frame(width: 180, height: 180)
                .blur(radius: 2)
                .offset(x: 90, y: -60)

            // Medium orb bottom-left
            Circle()
                .fill(Color.spendyAccentLight.opacity(0.12))
                .frame(width: 130, height: 130)
                .blur(radius: 1)
                .offset(x: -100, y: 70)

            // Small accent orb mid-right
            Circle()
                .fill(Color.white.opacity(0.05))
                .frame(width: 80, height: 80)
                .offset(x: 60, y: 50)
        }
        .allowsHitTesting(false)
    }

    private var trendIcon: some View {
        ZStack {
            Circle()
                .fill(.ultraThinMaterial)
                .frame(width: 46, height: 46)
                .overlay {
                    Circle()
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                }

            Image(systemName: totalBalance >= 0 ? "arrow.up.right" : "arrow.down.right")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
        }
        .shadow(color: Color.black.opacity(0.15), radius: 6, x: 0, y: 3)
    }

    private var balanceStatsRow: some View {
        HStack(spacing: 12) {
            // Income card
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Color.spendyGreen.opacity(0.25))
                        .frame(width: 34, height: 34)

                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color(hex: "6EF0C4"))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("ENTRATE")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.white.opacity(0.6))
                        .tracking(0.8)

                    Text(
                        viewModel.expenses.lazy.filter { $0.amount > 0 }.reduce(0) {
                            $0 + $1.amount
                        },
                        format: .currency(code: "EUR")
                    )
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color.white.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.white.opacity(0.12), lineWidth: 0.5)
            }

            // Expenses card
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Color.spendyRed.opacity(0.25))
                        .frame(width: 34, height: 34)

                    Image(systemName: "arrow.down.left")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color(hex: "FF9494"))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("USCITE")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.white.opacity(0.6))
                        .tracking(0.8)

                    Text(
                        abs(
                            viewModel.expenses.lazy.filter { $0.amount < 0 }.reduce(0) {
                                $0 + $1.amount
                            }
                        ),
                        format: .currency(code: "EUR")
                    )
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color.white.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.white.opacity(0.12), lineWidth: 0.5)
            }
        }
    }

    private var filterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(TransactionFilter.allCases, id: \.self) { filter in
                    FilterChip(
                        title: filter.rawValue,
                        isSelected: selectedFilter == filter,
                        action: {
                            withAnimation(.smooth(duration: 0.3)) {
                                selectedFilter = filter
                            }
                        }
                    )
                }
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 4)
        }
    }

    private var recentTransactionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section header
            HStack {
                Text("Transazioni Recenti")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.spendyText)

                Spacer()

                NavigationLink(destination: AllExpensesView()) {
                    HStack(spacing: 4) {
                        Text("Vedi tutte")
                            .font(.system(size: 14, weight: .semibold))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundStyle(Color.spendyGradient)
                }
            }

            if filteredExpenses.isEmpty {
                emptyStateView
            } else {
                SpendyCard(style: .default, padding: 0, cornerRadius: 20) {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(filteredExpenses.prefix(4)), id: \.id) { expense in
                            NavigationLink(destination: ExpenseDetailView(expense: expense)) {
                                ExpenseRow(expense: expense)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)

                            if expense.id != filteredExpenses.prefix(4).last?.id {
                                Divider()
                                    .padding(.leading, 74)
                                    .padding(.trailing, 16)
                            }
                        }
                    }
                }
            }
        }
    }

    private var uploadSection: some View {
        NavigationLink(destination: UploadView()) {
            SpendyCard(style: .default, padding: 16, cornerRadius: 20) {
                HStack(spacing: 16) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.spendyGradientSubtle)
                            .frame(width: 48, height: 48)

                        Image(systemName: "doc.badge.plus")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundStyle(Color.spendyGradient)
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text("Importa CSV")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.spendyText)

                        Text("Carica transazioni dalla banca")
                            .font(.system(size: 13))
                            .foregroundColor(.spendySecondaryText)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.spendyTertiaryText)
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Toolbar Items (Per pulizia del body)

    private var leadingToolbarItem: ToolbarItem<(), some View> {
        ToolbarItem(placement: .navigationBarLeading) {
            Button(action: { showingProfile = true }) {
                ZStack {
                    // Gradient ring
                    Circle()
                        .fill(Color.spendyGradient)
                        .frame(width: 36, height: 36)

                    Circle()
                        .fill(Color.spendyGradientDeep)
                        .frame(width: 32, height: 32)

                    Group {
                        if let user = authManager.currentUser {
                            Text(user.initials)
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                        } else {
                            Image(systemName: "person.fill")
                                .font(.system(size: 14, weight: .semibold))
                        }
                    }
                    .foregroundStyle(.white)
                }
            }
        }
    }

    private var principalToolbarItem: ToolbarItem<(), some View> {
        ToolbarItem(placement: .principal) {
            Text("Spendy")
                .font(.system(size: 19, weight: .bold, design: .rounded))
                .foregroundStyle(Color.spendyGradient)
        }
    }

    private var trailingToolbarItem: ToolbarItem<(), some View> {
        ToolbarItem(placement: .navigationBarTrailing) {
            HStack(spacing: 10) {
                Button(action: { showingDeleteAlert = true }) {
                    ZStack {
                        Circle()
                            .fill(
                                viewModel.expenses.isEmpty
                                ? Color.spendyBackgroundDark
                                : Color.spendyRedLight
                            )
                            .frame(width: 34, height: 34)

                        Image(systemName: "trash")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(
                                viewModel.expenses.isEmpty
                                ? .spendyTertiaryText
                                : .spendyRed
                            )
                    }
                }
                .disabled(viewModel.expenses.isEmpty)

                NavigationLink(destination: AddExpenseView()) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(Color.spendyGradient)
                        .symbolRenderingMode(.hierarchical)
                }
            }
        }
    }

    // Funzioni helper rimaste uguali ma spostate per pulizia
    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.spendyOrange)
                .font(.system(size: 16, weight: .semibold))

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

    private var emptyStateView: some View {
        SpendyCard(style: .gradientBordered, padding: 36, cornerRadius: 20) {
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.spendyGradientSubtle)
                        .frame(width: 72, height: 72)

                    Image(systemName: "tray.fill")
                        .font(.system(size: 30, weight: .medium))
                        .foregroundStyle(Color.spendyGradient)
                }

                VStack(spacing: 6) {
                    Text("Nessuna transazione")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.spendyText)

                    Text("Le tue transazioni appariranno qui")
                        .font(.system(size: 13))
                        .foregroundColor(.spendySecondaryText)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
}

// ---------------------------------------------------------
// 3. COMPONENTI SECONDARI OTTIMIZZATI
// ---------------------------------------------------------

struct ExpenseRow: View {
    let expense: Expense

    // Cache di valori computati semplici
    private var categoryColor: Color { CategoryMapper.color(for: expense.category) }
    private var categoryIcon: String { CategoryMapper.icon(for: expense.category) }

    private var isIncome: Bool { expense.amount >= 0 }

    var body: some View {
        HStack(spacing: 14) {
            // Category icon with colored circular background
            ZStack {
                Circle()
                    .fill(categoryColor.opacity(0.14))
                    .frame(width: 46, height: 46)

                Image(systemName: categoryIcon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(categoryColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(expense.userDescription)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.spendyText)
                    .lineLimit(1)

                if let date = expense.date {
                    // QUI SI USA L'ESTENSIONE DI DATE
                    Text(date.formattedDescription(withTime: true))
                        .font(.system(size: 12))
                        .foregroundColor(.spendySecondaryText)
                }
            }

            Spacer()

            // Amount with semantic color chip
            Text(expense.amount, format: .currency(code: expense.currency ?? "EUR"))
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundColor(isIncome ? .spendyGreen : .spendyRed)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(isIncome ? Color.spendyGreenLight : Color.spendyRedLight)
                .clipShape(Capsule())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

// StatItem e FilterChip ottimizzati per contrasto e dimensione
struct StatItem: View {
    let title: String
    let value: Double
    let icon: String
    let positive: Bool

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 32, height: 32)

                Image(systemName: icon)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 0) {
                Text(title)
                    .font(.caption2)
                    .textCase(.uppercase)
                    .foregroundColor(.white.opacity(0.7))
                Text(value, format: .currency(code: "EUR"))
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(isSelected ? .white : .spendySecondaryText)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background {
                    if isSelected {
                        Capsule()
                            .fill(Color.spendyGradient)
                            .shadow(
                                color: Color.spendyShadowPrimary,
                                radius: 8,
                                x: 0,
                                y: 3
                            )
                    } else {
                        Capsule()
                            .fill(Color.spendySurface)
                            .overlay {
                                Capsule()
                                    .stroke(Color.spendyBorderSubtle, lineWidth: 1)
                            }
                            .shadow(
                                color: Color.spendyShadowNear,
                                radius: 4,
                                x: 0,
                                y: 2
                            )
                    }
                }
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}
