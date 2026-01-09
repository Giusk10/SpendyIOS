import SwiftUI

struct AuthView: View {
    @StateObject private var authManager = AuthManager.shared
    @State private var isLoginMode = true
    @State private var username = ""
    @State private var password = ""
    @State private var email = ""
    @State private var name = ""
    @State private var surname = ""
    
    enum Field: Hashable {
        case username, password, email, name, surname
    }
    
    @FocusState private var focusedField: Field?
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.spendyBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 30) {
                        
                        // Logo / Header
//                        Image("SpendyLogo")
//                            .resizable()
//                            .scaledToFit()
//                            .frame(width: 80, height: 80)
//                            .clipShape(RoundedRectangle(cornerRadius: 16))
//                            .padding(.top, 40)
                        
                        VStack(spacing: 12) {
                            Text("Bentornato su Spendy")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(.spendyText)
                                .multilineTextAlignment(.center)
                            
                            Text("Gestisci in modo smart i conti condivisi e tieni tutto sotto controllo.")
                                .font(.body)
                                .foregroundColor(.spendySecondaryText)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .padding(.top, 40)
                        
                        // Card Area
                        VStack(spacing: 24) {
                            
                            // Form Fields
                            VStack(alignment: .leading, spacing: 16) {
                                Group {
                                    // Username Field
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text(isLoginMode ? "Username o email" : "Username")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.spendyText)
                                        
                                        ZStack(alignment: .leading) {
                                            if username.isEmpty {
                                                Text(isLoginMode ? "es. giulia.rossi" : "Username")
                                                    .foregroundColor(.spendyText.opacity(0.6)) // Darker placeholder
                                                    .padding(.horizontal, 16)
                                            }
                                            TextField("", text: $username)
                                                .focused($focusedField, equals: .username)
                                                .foregroundColor(.spendyText)
                                                .padding()
                                        }
                                        .background(Color.spendyBackground)
                                        .cornerRadius(8)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                        )
                                        .contentShape(Rectangle())
                                        .onTapGesture { focusedField = .username }
                                        .autocapitalization(.none)
                                    }
                                    
                                    // Password Field
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Password")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.spendyText)
                                        
                                        ZStack(alignment: .leading) {
                                            if password.isEmpty {
                                                Text("La tua password")
                                                    .foregroundColor(.spendyText.opacity(0.6)) // Darker placeholder
                                                    .padding(.horizontal, 16)
                                            }
                                            SecureField("", text: $password)
                                                .focused($focusedField, equals: .password)
                                                .foregroundColor(.spendyText)
                                                .padding()
                                        }
                                        .background(Color.spendyBackground)
                                        .cornerRadius(8)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                        )
                                        .contentShape(Rectangle())
                                        .onTapGesture { focusedField = .password }
                                    }
                                    
                                    if !isLoginMode {
                                        // Email Field
                                        VStack(alignment: .leading, spacing: 8) {
                                            Text("Email")
                                                .font(.subheadline)
                                                .fontWeight(.semibold)
                                                .foregroundColor(.spendyText)
                                            
                                            ZStack(alignment: .leading) {
                                                if email.isEmpty {
                                                    Text("Email")
                                                        .foregroundColor(.spendyText.opacity(0.6)) // Darker placeholder
                                                        .padding(.horizontal, 16)
                                                }
                                                TextField("", text: $email)
                                                    .focused($focusedField, equals: .email)
                                                    .foregroundColor(.spendyText)
                                                    .padding()
                                            }
                                            .background(Color.spendyBackground)
                                            .cornerRadius(8)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                            )
                                            .contentShape(Rectangle())
                                            .onTapGesture { focusedField = .email }
                                            .autocapitalization(.none)
                                            .keyboardType(.emailAddress)
                                        }
                                        
                                        HStack(spacing: 12) {
                                            // Name Field
                                            VStack(alignment: .leading, spacing: 8) {
                                                Text("Nome")
                                                    .font(.subheadline)
                                                    .fontWeight(.semibold)
                                                    .foregroundColor(.spendyText)
                                                
                                                ZStack(alignment: .leading) {
                                                    if name.isEmpty {
                                                        Text("Nome")
                                                            .foregroundColor(.spendyText.opacity(0.6)) // Darker placeholder
                                                            .padding(.horizontal, 16)
                                                    }
                                                    TextField("", text: $name)
                                                        .focused($focusedField, equals: .name)
                                                        .foregroundColor(.spendyText)
                                                        .padding()
                                                }
                                                .background(Color.spendyBackground)
                                                .cornerRadius(8)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 8)
                                                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                                )
                                                .contentShape(Rectangle())
                                                .onTapGesture { focusedField = .name }
                                            }
                                            
                                            // Surname Field
                                            VStack(alignment: .leading, spacing: 8) {
                                                Text("Cognome")
                                                    .font(.subheadline)
                                                    .fontWeight(.semibold)
                                                    .foregroundColor(.spendyText)
                                                
                                                ZStack(alignment: .leading) {
                                                    if surname.isEmpty {
                                                        Text("Cognome")
                                                            .foregroundColor(.spendyText.opacity(0.6)) // Darker placeholder
                                                            .padding(.horizontal, 16)
                                                    }
                                                    TextField("", text: $surname)
                                                        .focused($focusedField, equals: .surname)
                                                        .foregroundColor(.spendyText)
                                                        .padding()
                                                }
                                                .background(Color.spendyBackground)
                                                .cornerRadius(8)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 8)
                                                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                                )
                                                .contentShape(Rectangle())
                                                .onTapGesture { focusedField = .surname }
                                            }
                                        }
                                    }
                                }
                            }
                            
                            if let error = authManager.errorMessage {
                                Text(error)
                                    .foregroundColor(.spendyRed)
                                    .font(.caption)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            
                            Button(action: handleAction) {
                                if authManager.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text(isLoginMode ? "Accedi" : "Registrati")
                                        .font(.headline)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.spendyPrimary)
                                        .foregroundColor(.white)
                                        .cornerRadius(12)
                                }
                            }
                            .disabled(authManager.isLoading)
                            
                            Button(action: { 
                                withAnimation {
                                    isLoginMode.toggle() 
                                }
                            }) {
                                Text(isLoginMode ? "Non hai ancora un account? Registrati ora" : "Hai già un account? Accedi")
                                    .font(.subheadline)
                                    .foregroundColor(.spendyPrimary)
                            }
                        }
                        .padding(24)
                        .background(Color.white)
                        .cornerRadius(20)
                        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                        .padding(.horizontal)
                        
                        Spacer()
                    }
                    .padding(.bottom, 40)
                }
            }
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
