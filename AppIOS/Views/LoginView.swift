import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var username = ""
    @State private var password = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Login")
                .font(.largeTitle)
                .bold()
            
            TextField("Username", text: $username)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.none)
            
            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            if let error = authViewModel.errorMessage {
                Text(error)
                    .foregroundColor(.red)
            }
            
            Button(action: {
                let payload = LoginPayload(username: username, password: password)
                authViewModel.login(payload: payload)
            }) {
                if authViewModel.isLoading {
                    ProgressView()
                } else {
                    Text("Login")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            
            NavigationLink(destination: RegisterView()) {
                Text("Don't have an account? Register")
                    .foregroundColor(.blue)
            }
        }
        .padding()
    }
}
