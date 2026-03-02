import SwiftUI
import UniformTypeIdentifiers

struct UploadView: View {
    @State private var isImporting: Bool = false
    @State private var message: String = ""
    @State private var isSuccess: Bool = false
    @State private var isLoading: Bool = false

    var body: some View {
        ZStack {
            Color.spendyBackground
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {

                    // MARK: - Drop Zone Card
                    SpendyCard(style: .gradientBordered, padding: 0) {
                        VStack(spacing: 28) {
                            // Dashed upload area
                            ZStack {
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(
                                        style: StrokeStyle(
                                            lineWidth: 2,
                                            dash: [8, 5]
                                        )
                                    )
                                    .foregroundStyle(Color.spendyGradientBorder)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 180)

                                VStack(spacing: 16) {
                                    // Icon with gradient background circle
                                    ZStack {
                                        Circle()
                                            .fill(Color.spendyGradientSubtle)
                                            .frame(width: 80, height: 80)

                                        Image(systemName: isLoading ? "arrow.triangle.2.circlepath" : "doc.text.viewfinder")
                                            .font(.system(size: 36, weight: .medium))
                                            .foregroundStyle(Color.spendyGradient)
                                            .rotationEffect(isLoading ? .degrees(360) : .degrees(0))
                                            .animation(
                                                isLoading
                                                    ? .linear(duration: 1.2).repeatForever(autoreverses: false)
                                                    : .default,
                                                value: isLoading
                                            )
                                    }

                                    VStack(spacing: 6) {
                                        Text(isLoading ? "Importazione in corso..." : "Trascina il file qui")
                                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                                            .foregroundColor(.spendyText)

                                        Text(isLoading ? "Attendi qualche istante" : "oppure usa il pulsante qui sotto")
                                            .font(.system(size: 13))
                                            .foregroundColor(.spendyTertiaryText)
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 20)

                            // Title and description
                            VStack(spacing: 8) {
                                Text("Importa Spese")
                                    .font(.system(size: 22, weight: .bold, design: .rounded))
                                    .foregroundColor(.spendyText)

                                Text("Carica il tuo file CSV per importare\nautomaticamente le transazioni")
                                    .font(.system(size: 14))
                                    .foregroundColor(.spendySecondaryText)
                                    .multilineTextAlignment(.center)
                                    .lineSpacing(3)
                            }

                            // File picker button
                            SpendyButton(
                                isLoading ? "Caricamento..." : "Seleziona File CSV",
                                variant: .secondary,
                                isLoading: false,
                                isDisabled: isLoading,
                                leadingIcon: isLoading ? nil : "square.and.arrow.up"
                            ) {
                                isImporting = true
                            }
                            .padding(.horizontal, 4)
                            .padding(.bottom, 4)
                        }
                        .padding(16)
                    }

                    // MARK: - Status Message Card
                    if !message.isEmpty {
                        SpendyCard(style: .default, padding: 16) {
                            HStack(spacing: 14) {
                                ZStack {
                                    Circle()
                                        .fill(isSuccess ? Color.spendyGreenLight : Color.spendyRedLight)
                                        .frame(width: 40, height: 40)

                                    Image(systemName: isSuccess ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundColor(isSuccess ? .spendyGreen : .spendyRed)
                                }

                                VStack(alignment: .leading, spacing: 3) {
                                    Text(isSuccess ? "Completato" : "Errore")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(isSuccess ? .spendyGreen : .spendyRed)

                                    Text(message)
                                        .font(.system(size: 13))
                                        .foregroundColor(.spendySecondaryText)
                                        .fixedSize(horizontal: false, vertical: true)
                                }

                                Spacer()
                            }
                        }
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }

                    // MARK: - Supported Formats Info
                    HStack(spacing: 6) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 12))
                        Text("Formati supportati: CSV")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(.spendyTertiaryText)
                    .padding(.top, 4)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 120)
            }
        }
        .fileImporter(
            isPresented: $isImporting,
            allowedContentTypes: [.commaSeparatedText],
            allowsMultipleSelection: false
        ) { result in
            handleFileImport(result)
        }
        .navigationTitle("Importa")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func handleFileImport(_ result: Result<[URL], Error>) {
        do {
            guard let selectedFile: URL = try result.get().first else { return }

            if selectedFile.startAccessingSecurityScopedResource() {
                defer { selectedFile.stopAccessingSecurityScopedResource() }

                do {
                    let data = try Data(contentsOf: selectedFile)
                    let fileName = selectedFile.lastPathComponent

                    isLoading = true
                    withAnimation {
                        message = ""
                    }

                    Task {
                        do {
                            let success = try await ExpenseService.shared.importCSV(
                                data: data, fileName: fileName)
                            await MainActor.run {
                                isLoading = false
                                isSuccess = success
                                withAnimation(.spring()) {
                                    message =
                                        success
                                        ? "Upload completato con successo!" : "Upload fallito."
                                }
                            }
                        } catch {
                            await MainActor.run {
                                isLoading = false
                                isSuccess = false
                                withAnimation(.spring()) {
                                    message = "Errore: \(error.localizedDescription)"
                                }
                            }
                        }
                    }
                } catch {
                    message = "Impossibile accedere ai dati del file"
                    isSuccess = false
                }
            } else {
                message = "Permesso negato per accedere al file"
                isSuccess = false
            }
        } catch {
            message = "Errore: \(error.localizedDescription)"
            isSuccess = false
        }
    }
}
