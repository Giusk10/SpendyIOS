import SwiftUI
import UniformTypeIdentifiers

struct UploadView: View {
    @State private var isImporting: Bool = false
    @State private var message: String = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Import Expenses")
                .font(.title)
            
            Button("Select CSV File") {
                isImporting = true
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
            
            Text(message)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding()
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
                    
                    try ExpenseService.shared.importCSV(url: selectedFile)
                    message = "File queued for upload: \(selectedFile.lastPathComponent)\nIt will be processed when online."
                } else {
                    message = "Permission denied to access file."
                }
            } catch {
                message = "Error: \(error.localizedDescription)"
            }
        }
        .navigationTitle("Import")
    }
}
