import SwiftUI
import Charts

struct AnalyticsView: View {
    @StateObject private var viewModel = AnalyticsViewModel()
    
    // Mock state for UI filters
    @State private var selectedYear = "2025"
    @State private var selectedFilter = "Tutte le spese importate"
    @State private var selectedMonth: String? = nil
    
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
                            // 1. Filter Section
                            VStack(spacing: 16) {
                                // Year Filter
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Anno di analisi")
                                        .font(.caption)
                                        .foregroundColor(.spendySecondaryText)
                                        .fontWeight(.medium)
                                    
                                    Menu {
                                        ForEach(Array(2020...2030), id: \.self) { year in
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
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Filtra Spese")
                                        .font(.caption)
                                        .foregroundColor(.spendySecondaryText)
                                        .fontWeight(.medium)
                                    
                                    // Mode Selection
                                    Menu {
                                        Button("Tutte le spese") {
                                            viewModel.filterMode = .all
                                            selectedFilter = "Tutte le spese"
                                        }
                                        Button("Per Mese") {
                                            viewModel.filterMode = .month
                                            selectedFilter = "Per Mese"
                                        }
                                        Button("Per Data") {
                                            viewModel.filterMode = .dateRange
                                            selectedFilter = "Per Data"
                                        }
                                    } label: {
                                        HStack {
                                            Text(selectedFilter)
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
                                    
                                    // Conditional Inputs
                                    if viewModel.filterMode == .month {
                                        HStack {
                                            Picker("Mese", selection: $viewModel.selectedMonth) {
                                                ForEach(1...12, id: \.self) { month in
                                                    Text(Calendar.current.monthSymbols[month - 1])
                                                        .tag(month)
                                                }
                                            }
                                            .pickerStyle(.menu)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 4) // Slight padding increase to "make bigger"
                                            .background(Color.white)
                                            .cornerRadius(8)
                                            
                                            Picker("Anno", selection: $viewModel.selectedYearInt) {
                                                ForEach(Array(2020...2030), id: \.self) { year in
                                                    Text(String(year)).tag(year)
                                                }
                                            }
                                            .pickerStyle(.menu)
                                            .frame(maxWidth: .infinity)
                                            .background(Color.white)
                                            .cornerRadius(8)
                                        }
                                    } else if viewModel.filterMode == .dateRange {
                                        VStack(spacing: 8) {
                                            DatePicker("Da", selection: $viewModel.selectedDateRange.start, displayedComponents: .date)
                                            DatePicker("A", selection: $viewModel.selectedDateRange.end, displayedComponents: .date)
                                        }
                                        .padding(8)
                                        .background(Color.white)
                                        .cornerRadius(8)
                                    }
                                    
                                    // Apply Button
                                    Button(action: {
                                        viewModel.applyFilters()
                                    }) {
                                        Text("Applica filtri")
                                            .font(.caption)
                                            .fontWeight(.bold)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 12)
                                            .background(Color.spendyPrimary)
                                            .foregroundColor(.white)
                                            .cornerRadius(12)
                                    }
                                }
                                .padding(.horizontal)
                            }
                            
                            // 2. Summary Cards
                            ScrollView(.horizontal, showsIndicators: false) {
                                LazyHStack(spacing: 16) {
                                    SummaryCard(title: "USCITE TOTALI", value: viewModel.totalBalance, subtitle: "\(viewModel.totalTransactions) movimenti monitorati", color: .spendyRed)
                                    SummaryCard(title: "SPESA MEDIA", value: viewModel.averageExpense, subtitle: "Calcolata su tutte le transazioni", color: .spendyBlue)
                                    SummaryCard(title: "USCITA MAGGIORE", value: viewModel.highestExpense, subtitle: "Il movimento più rilevante registrato", color: .spendyOrange)
                                }
                                .padding(.horizontal)
                            }
                            
                            // 3. Chart Section
                            VStack(alignment: .leading, spacing: 16) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Andamento mensile")
                                        .font(.headline)
                                        .foregroundColor(.spendyText)
                                    Text("Importi assoluti delle uscite registrate per mese")
                                        .font(.caption)
                                        .foregroundColor(.spendySecondaryText)
                                }
                                .padding(.horizontal)
                                
                                Chart {
                                    ForEach(viewModel.monthlyData) { item in
                                        LineMark(
                                            x: .value("Data", item.month),
                                            y: .value("Importo", item.amount)
                                        )
                                        .interpolationMethod(.catmullRom)
                                        .foregroundStyle(Color.spendyPrimary.gradient)
                                        .lineStyle(StrokeStyle(lineWidth: 3))
                                        
                                        AreaMark(
                                            x: .value("Data", item.month),
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
                                    
                                    if let selectedMonth, let item = viewModel.monthlyData.first(where: { $0.month == selectedMonth }) {
                                        RuleMark(x: .value("Data", selectedMonth))
                                            .foregroundStyle(Color.spendySecondaryText.opacity(0.5))
                                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                                            .annotation(position: .topLeading, alignment: .center) {
                                                VStack(alignment: .leading, spacing: 4) {
                                                    Text(item.month)
                                                        .font(.caption)
                                                        .foregroundColor(.secondary)
                                                    
                                                    HStack(spacing: 4) {
                                                        Text("value :")
                                                            .font(.caption)
                                                            .foregroundColor(.spendyPrimary)
                                                        Text(item.amount, format: .currency(code: "EUR"))
                                                            .font(.caption)
                                                            .fontWeight(.bold)
                                                            .foregroundColor(.spendyPrimary)
                                                    }
                                                }
                                                .padding(12)
                                                .background(Color.white)
                                                .cornerRadius(12)
                                                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                                                )
                                            }
                                    }
                                }
                                .chartYAxis {
                                    AxisMarks(position: .leading)
                                }
                                .frame(height: 250)
                                .padding(.horizontal)
                                .chartOverlay { proxy in
                                    GeometryReader { geometry in
                                        Rectangle().fill(.clear).contentShape(Rectangle())
                                            .gesture(
                                                DragGesture()
                                                    .onChanged { value in
                                                        let x = value.location.x
                                                        if let month: String = proxy.value(atX: x) {
                                                            selectedMonth = month
                                                        }
                                                    }
                                                    .onEnded { _ in
                                                        selectedMonth = nil
                                                    }
                                            )
                                            .onTapGesture { location in
                                                 let x = location.x
                                                 if let month: String = proxy.value(atX: x) {
                                                     selectedMonth = month
                                                 }
                                            }
                                    }
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
            .background(Color.spendyBackground)
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
        .frame(width: 250, height: 130, alignment: .topLeading)
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .overlay(
            Rectangle()
                .frame(height: 4)
                .foregroundColor(color),
            alignment: .top
        )
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}
