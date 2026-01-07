import Foundation
import Combine

class AuthViewModel: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    func login(payload: LoginPayload) {
        isLoading = true
        errorMessage = nil
        Task {
            do {
                let response = try await AuthService.shared.login(payload: payload)
                DispatchQueue.main.async {
                    HTTPClient.shared.setToken(response.token)
                    self.isAuthenticated = true
                    self.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
    
    func register(payload: RegisterPayload) {
        isLoading = true
        errorMessage = nil
        Task {
            do {
                _ = try await AuthService.shared.register(payload: payload)
                DispatchQueue.main.async {
                    self.isLoading = false
                    // Optionally auto-login or prompt user
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
    
    func logout() {
        HTTPClient.shared.clearToken()
        isAuthenticated = false
    }
}
