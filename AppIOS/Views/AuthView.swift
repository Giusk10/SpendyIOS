import SwiftUI

struct AuthView: View {
    @StateObject private var authManager = AuthManager.shared
    @State private var isLoginMode = true
    @State private var username = ""
    @State private var password = ""
    @State private var email = ""
    @State private var name = ""
    @State private var surname = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text(isLoginMode ? "Welcome Back" : "Create Account")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                TextField("Username", text: $username)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                
                SecureField("Password", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                if !isLoginMode {
                    TextField("Email", text: $email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)
                    
                    TextField("Name", text: $name)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    TextField("Surname", text: $surname)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                if let error = authManager.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                }
                
                Button(action: handleAction) {
                    if authManager.isLoading {
                        ProgressView()
                    } else {
                        Text(isLoginMode ? "Log In" : "Register")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
                .disabled(authManager.isLoading)
                
                Button(action: { isLoginMode.toggle() }) {
                    Text(isLoginMode ? "Don't have an account? Register" : "Already have an account? Log In")
                        .font(.footnote)
                }
                
                Spacer()
            }
            .padding()
            .navigationBarHidden(true)
        }
    }
    
    private func handleAction() {
        Task {
            if isLoginMode {
                _ = await authManager.login(username: username, password: password)
            } else {
                _ = await authManager.register(username: username, password: password, email: email, name: name, surname: surname)
            }
        }
    }
}
