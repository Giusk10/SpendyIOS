import SwiftUI

struct UserProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var authManager = AuthManager.shared
    @State private var name = ""
    @State private var surname = ""
    @State private var isLoading = false
    @State private var isFetching = false
    @State private var message: String?
    @State private var isError = false
    @State private var showingLogout = false
    @FocusState private var focusedField: Field?
    private enum Field { case name, surname }

    var body: some View {
        NavigationStack {
            Form {
                if let user = authManager.currentUser {
                    Section {
                        HStack(spacing: 16) {
                            ProfileAvatar(user: user)
                            Text(user.fullName).font(.title3.bold())
                        }
                        .padding(.vertical, 8)
                        LabeledContent("Email", value: user.email)
                        LabeledContent("Username", value: user.username)
                    }
                    Section("Informazioni personali") {
                        TextField("Nome", text: $name).textContentType(.givenName)
                            .focused($focusedField, equals: .name)
                        TextField("Cognome", text: $surname).textContentType(.familyName)
                            .focused($focusedField, equals: .surname)
                    }
                    Section {
                        SpendyButton("Salva modifiche", isLoading: isLoading,
                                     isDisabled: !hasChanges(user), leadingIcon: "checkmark") { saveProfile() }
                    }
                    .listRowInsets(EdgeInsets()).listRowBackground(Color.clear)
                } else if isFetching {
                    ProgressView("Caricamento profilo…")
                } else {
                    SpendyEmptyState(title: "Profilo non disponibile",
                                     message: "Controlla la connessione e riprova.", icon: "person.crop.circle")
                    Button("Riprova") { Task { await loadProfile() } }
                }
                if let message {
                    Section { SpendyMessage(message: message, isError: isError) }
                        .listRowInsets(EdgeInsets()).listRowBackground(Color.clear)
                }
                Section {
                    Button("Esci dall'account", role: .destructive) { showingLogout = true }
                }
            }
            .disabled(isLoading)
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Profilo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Chiudi") { dismiss() }.disabled(isLoading)
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Fine") { focusedField = nil }
                }
            }
            .task {
                if authManager.currentUser == nil { await loadProfile() }
                copyFields()
            }
            .onChange(of: authManager.currentUser) { oldUser, newUser in
                if oldUser == nil && newUser != nil { copyFields() }
            }
            .confirmationDialog("Uscire dall'account?", isPresented: $showingLogout,
                                titleVisibility: .visible) {
                Button("Esci", role: .destructive) {
                    authManager.logout()
                    dismiss()
                }
            }
        }
        .interactiveDismissDisabled(isLoading)
    }

    private func hasChanges(_ user: User) -> Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !surname.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && (name != user.name || surname != user.surname)
    }

    private func loadProfile() async {
        isFetching = true
        await authManager.fetchUserProfile()
        isFetching = false
        copyFields()
    }

    private func copyFields() {
        if let user = authManager.currentUser {
            name = user.name
            surname = user.surname
        }
    }

    private func saveProfile() {
        guard !isLoading else { return }
        focusedField = nil
        isLoading = true
        message = nil
        Task {
            let success = await authManager.updateProfile(name: name, surname: surname)
            isLoading = false
            isError = !success
            message = success ? "Profilo aggiornato." : "Salvataggio non riuscito. Riprova."
        }
    }
}
