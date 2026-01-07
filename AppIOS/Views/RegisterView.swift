import SwiftUI

struct RegisterView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var username = ""
    @State private var password = ""
    @State private var name = ""
    @State private var surname = ""
    @State private var email = ""
    
    var body: some View {
        Form {
            Section(header: Text("Account Details")) {
                TextField("Username", text: $username)
                SecureField("Password", text: $password)
            }
            
            Section(header: Text("Personal Info")) {
                TextField("Name", text: $name)
                TextField("Surname", text: $surname)
                TextField("Email", text: $email)
            }
            
            if let error = authViewModel.errorMessage {
                Text(error)
                    .foregroundColor(.red)
            }
            
            Button("Register") {
                let payload = RegisterPayload(
                    username: username,
                    password: password,
                    name: name,
                    surname: surname,
                    email: email
                )
                authViewModel.register(payload: payload)
            }
            .disabled(authViewModel.isLoading)
        }
        .navigationTitle("Register")
    }
}
