import SwiftUI
import UniformTypeIdentifiers

struct UploadView: View {
    @State private var isImporting = false
    @State private var message: String?
    @State private var isSuccess = false
    @State private var isLoading = false
    @State private var fileName: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                SpendyCard(padding: 24) {
                    VStack(alignment: .leading, spacing: 20) {
                        Image(systemName: "doc.badge.arrow.up")
                            .font(.largeTitle).foregroundStyle(Color.spendyPrimary)
                            .accessibilityHidden(true)
                        Text("Tutte le transazioni, in un posto.")
                            .font(.title2.bold()).accessibilityAddTraits(.isHeader)
                        Text("Seleziona il file CSV esportato dalla tua banca. Spendy importerà le transazioni nel tuo account.")
                            .font(.body).foregroundStyle(Color.spendySecondaryText)
                        if let fileName {
                            Label(fileName, systemImage: "doc.text").font(.subheadline)
                        }
                        SpendyButton("Seleziona file CSV", isLoading: isLoading,
                                     leadingIcon: "folder") { isImporting = true }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                if let message { SpendyMessage(message: message, isError: !isSuccess) }
                Label("Formato supportato: CSV", systemImage: "info.circle")
                    .font(.footnote).foregroundStyle(Color.spendySecondaryText)
            }
            .frame(maxWidth: SpendyLayout.contentWidth)
            .padding(SpendyLayout.pagePadding)
            .frame(maxWidth: .infinity)
        }
        .background(Color.spendyBackground)
        .navigationTitle("Importa transazioni")
        .navigationBarTitleDisplayMode(.inline)
        .fileImporter(isPresented: $isImporting, allowedContentTypes: [.commaSeparatedText],
                      allowsMultipleSelection: false, onCompletion: handleFileImport)
    }

    private func handleFileImport(_ result: Result<[URL], Error>) {
        guard !isLoading else { return }
        do {
            guard let url = try result.get().first else { return }
            isLoading = true
            message = nil
            fileName = url.lastPathComponent
            Task {
                defer { isLoading = false }
                do {
                    // The worker owns security-scoped access for the entire blocking read.
                    let data = try await CSVFileReader.read(url)
                    isSuccess = try await ExpenseService.shared.importCSV(data: data, fileName: url.lastPathComponent)
                    message = isSuccess ? "Importazione completata. Le transazioni sono aggiornate."
                        : "Importazione non riuscita. Controlla il file e riprova."
                } catch {
                    isSuccess = false
                    message = "Impossibile importare il file. \(error.localizedDescription)"
                }
            }
        } catch {
            isSuccess = false
            message = error.localizedDescription
        }
    }
}

private enum CSVFileReader {
    @concurrent
    static func read(_ url: URL) async throws -> Data {
        let hasAccess = url.startAccessingSecurityScopedResource()
        defer { if hasAccess { url.stopAccessingSecurityScopedResource() } }
        return try Data(contentsOf: url)
    }
}

#Preview("Importa • Light") { NavigationStack { UploadView() }.preferredColorScheme(.light) }
#Preview("Importa • Dark") { NavigationStack { UploadView() }.preferredColorScheme(.dark) }
