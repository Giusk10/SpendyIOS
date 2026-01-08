import SwiftUI
import UniformTypeIdentifiers

struct UploadView: View {
    @State private var isImporting: Bool = false
    @State private var message: String = ""
    
    var body: some View {
        ZStack {
            Color.spendyBackground
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "arrow.up.doc.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.spendyPrimary)
                    
                    Text("Importa Spese")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.spendyText)
                    
                    Text("Carica il tuo file CSV per analizzare le tue spese")
                        .font(.body)
                        .foregroundColor(.spendySecondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.top, 40)
                
                // Action Area
                VStack(spacing: 20) {
                    Button(action: {
                        isImporting = true
                    }) {
                        HStack {
                            Image(systemName: "doc.text.fill")
                            Text("Seleziona file CSV")
                        }
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.spendyPrimary)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    
                    if !message.isEmpty {
                        Text(message)
                            .foregroundColor(message.contains("successful") ? .spendyGreen : .spendyRed)
                            .multilineTextAlignment(.center)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(10)
                            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                    }
                }
                .padding(.horizontal, 24)
                
                Spacer()
            }
        }
        .fileImporter(
            isPresented: $isImporting,
            allowedContentTypes: [.commaSeparatedText],
            allowsMultipleSelection: false
        ) { result in
            do {
                guard let selectedFile: URL = try result.get().first else { return }
                
                if selectedFile.startAccessingSecurityScopedResource() {
                    defer { selectedFile.stopAccessingSecurityScopedResource() }
                    
                    do {
                        // Read data synchronously while we have access
                        let data = try Data(contentsOf: selectedFile)
                        let fileName = selectedFile.lastPathComponent
                        
                        message = "Caricamento in corso..."
                        Task {
                            do {
                                let success = try await ExpenseService.shared.importCSV(data: data, fileName: fileName)
                                await MainActor.run {
                                    message = success ? "Upload completato con successo!" : "Upload fallito."
                                }
                            } catch {
                                await MainActor.run {
                                    message = "Errore: \(error.localizedDescription)"
                                }
                            }
                        }
                    } catch {
                         message = "Impossibile accedere ai dati del file: \(error.localizedDescription)"
                    }
                } else {
                    message = "Permesso negato per accedere al file."
                }
            } catch {
                message = "Errore: \(error.localizedDescription)"
            }
        }
        .navigationTitle("Importa")
        .navigationBarTitleDisplayMode(.inline)
    }
}
