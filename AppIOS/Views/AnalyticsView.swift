import SwiftUI
import Charts

struct AnalyticsView: View {
    @StateObject private var viewModel = AnalyticsViewModel()
    
    // Mock state for UI filters
    @State private var selectedYear = "2025"
    @State private var selectedFilter = "Tutte le spese importate"
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.spendyBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        
                        if viewModel.isLoading {
                            ProgressView()
                                .padding()
                        } else if let error = viewModel.errorMessage {
                            Text(error)
                                .foregroundColor(.spendyRed)
                                .padding()
                        } else {
                            // 1. Filter Section (Visual Only per screenshot)
                            VStack(spacing: 16) {
                                // Year Filter
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Anno di analisi")
                                        .font(.caption)
                                        .foregroundColor(.spendySecondaryText)
                                        .fontWeight(.medium)
                                    
                                    Menu {
                                        ForEach(2020...2030, id: \.self) { year in
                                            Button(String(year)) {
                                                selectedYear = String(year)
                                                viewModel.updateFilters(year: selectedYear)
                                            }
                                        }
                                    } label: {
                                        HStack {
                                            Text(selectedYear)
                                                .font(.body)
                                                .foregroundColor(.spendyText)
                                            Spacer()
                                            Image(systemName: "chevron.down")
                                                .foregroundColor(.spendySecondaryText)
                                                .font(.caption)
                                        }
                                        .padding()
                                        .background(Color.white)
                                        .cornerRadius(12)
                                        .shadow(color: Color.black.opacity(0.03), radius: 3, x: 0, y: 1)
                                    }
                                }
                                .padding(.horizontal)
                                
                                // Type Filter
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Mostra spese")
                                        .font(.caption)
                                        .foregroundColor(.spendySecondaryText)
                                        .fontWeight(.medium)
                                    
                                    HStack {
                                        Text(selectedFilter)
                                            .font(.body)
                                            .foregroundColor(.spendyText)
                                        Spacer()
                                        
                                        Button(action: {}) {
                                            Text("Applica filtri")
                                                .font(.caption)
                                                .fontWeight(.bold)
                                                .padding(.horizontal, 16)
                                                .padding(.vertical, 8)
                                                .background(Color.spendyPrimary)
                                                .foregroundColor(.white)
                                                .cornerRadius(8)
                                        }
                                    }
                                    .padding()
                                    .background(Color.white)
                                    .cornerRadius(12)
                                    .shadow(color: Color.black.opacity(0.03), radius: 3, x: 0, y: 1)
                                }
                                .padding(.horizontal)
                            }
                            
                            // 2. Summary Cards
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
                                    SummaryCard(title: "USCITE TOTALI", value: viewModel.totalBalance, subtitle: "\(viewModel.totalTransactions) movimenti monitorati", color: .spendyRed)
                                    SummaryCard(title: "SPESA MEDIA", value: viewModel.averageExpense, subtitle: "Calcolata su tutte le transazioni", color: .spendyBlue)
                                    SummaryCard(title: "USCITA MAGGIORE", value: viewModel.highestExpense, subtitle: "Il movimento più rilevante registrato", color: .spendyOrange) // Orange matches screenshot roughly (or can use Primary)
                                }
                                .padding(.horizontal)
                            }
                            
                            // 3. Chart Section
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Andamento mensile")
                                    .font(.headline)
                                    .foregroundColor(.spendyText)
                                    .padding(.horizontal)
                                
                                if viewModel.monthlyData.isEmpty {
                                    Text("Nessun dato disponibile")
                                        .font(.caption)
                                        .foregroundColor(.spendySecondaryText)
                                        .padding(.horizontal)
                                } else {
                                    Chart(viewModel.monthlyData) { item in
                                        LineMark(
                                            x: .value("Mese", item.month),
                                            y: .value("Importo", item.amount)
                                        )
                                        .interpolationMethod(.catmullRom)
                                        .foregroundStyle(Color.spendyPrimary.gradient)
                                        .lineStyle(StrokeStyle(lineWidth: 3))
                                        
                                        AreaMark(
                                            x: .value("Mese", item.month),
                                            y: .value("Importo", item.amount)
                                        )
                                        .interpolationMethod(.catmullRom)
                                        .foregroundStyle(
                                            LinearGradient(
                                                colors: [.spendyPrimary.opacity(0.2), .spendyPrimary.opacity(0.0)],
                                                startPoint: .top,
                                                endPoint: .bottom
                                            )
                                        )
                                    }
                                    .frame(height: 250)
                                    .padding(.horizontal)
                                }
                            }
                            .padding(.vertical)
                            .background(Color.white)
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.03), radius: 3, x: 0, y: 1)
                            .padding(.horizontal)
                            
                            // 4. Categories Section
                            LazyVStack(alignment: .leading, spacing: 16) {
                                Text("Categorie più rilevanti")
                                    .font(.headline)
                                    .foregroundColor(.spendyText)
                                    .padding(.horizontal)
                                
                                ForEach(viewModel.topCategories) { category in
                                    HStack {
                                        VStack(alignment: .leading) {
                                            Text(category.name)
                                                .font(.subheadline)
                                                .fontWeight(.semibold)
                                                .foregroundColor(.spendyText)
                                            Text("\(category.count) movimenti")
                                                .font(.caption)
                                                .foregroundColor(.spendySecondaryText)
                                        }
                                        Spacer()
                                        Text(category.amount, format: .currency(code: "EUR"))
                                            .font(.subheadline)
                                            .fontWeight(.bold)
                                            .foregroundColor(.spendyText)
                                    }
                                    .padding(.horizontal)
                                    Divider()
                                        .padding(.leading)
                                }
                            }
                            .padding(.vertical)
                            .background(Color.white)
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.03), radius: 3, x: 0, y: 1)
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Dashboard finanziaria")
            .navigationBarTitleDisplayMode(.inline)
            .background(Color.spendyBackground) // Ensure Nav stack bg
            .onAppear {
                viewModel.loadData()
                viewModel.fetchMonthlyStats(year: selectedYear)
            }
            .refreshable {
                viewModel.loadData()
            }
        }
    }
}

struct SummaryCard: View {
    let title: String
    let value: Double
    let subtitle: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 11))
                .fontWeight(.bold)
                .foregroundColor(.spendySecondaryText)
                .textCase(.uppercase)
                .kerning(0.5)
            
            Text(value, format: .currency(code: "EUR"))
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.spendyText)
            
            Text(subtitle)
                .font(.caption2)
                .foregroundColor(.spendySecondaryText)
                .lineLimit(2)
        }
        .frame(width: 250, height: 130, alignment: .topLeading) // Wider to match screenshot
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .overlay(
            Rectangle()
                .frame(height: 4)
                .foregroundColor(color),
            alignment: .top
        )
        // Add left border as per screenshot (red/blue/cyan vertical line on left)
        // Wait, screenshot shows colored BORDER TOP? No, screenshot shows "Red border top" for first card, "Blue border top" for second.
        // Actually, looking closely at the first screenshot:
        // "USCITE TOTALI" -> Card has a RED top border (or left?). It looks like a TOP border or maybe a FULL border but colored on top. 
        // Let's stick to the overlay top border I implemented, it's very close to the look.
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}
