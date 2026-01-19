import Foundation
import SwiftUI
import Combine
import LocalAuthentication

enum AuthState {
    case unauthenticated
    case authenticated
    case locked
    case pinSetup
}

class AuthManager: ObservableObject {
    static let shared = AuthManager()
    
    @Published var authState: AuthState = .unauthenticated
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let baseURL = "\(Constants.baseURL)/Auth/rest/auth"
    private let keychainService = "com.appios.auth"
    private let kAccessToken = "accessToken"
    private let kRefreshToken = "refreshToken"
    private let kUserPIN = "userPIN"
    
    private init() {
        checkInitialState()
    }
    
    private func checkInitialState() {
        // Cold Start Logic
        if let _ = getRefreshToken() {
            // We have a session, but app was killed.
            // Go to Locked state immediately.
            self.authState = .locked
        } else {
            self.authState = .unauthenticated
        }
    }
    
    // MARK: - Token Management
    
    func getAccessToken() -> String? {
        return readKeychain(account: kAccessToken)
    }
    
    func getRefreshToken() -> String? {
        return readKeychain(account: kRefreshToken)
    }
    
    func saveTokens(access: String, refresh: String) {
        saveKeychain(data: access.data(using: .utf8)!, account: kAccessToken)
        saveKeychain(data: refresh.data(using: .utf8)!, account: kRefreshToken)
    }
    
    func clearTokens() {
        deleteKeychain(account: kAccessToken)
        deleteKeychain(account: kRefreshToken)
    }
    
    // MARK: - PIN & Lock Management
    
    func hasPin() -> Bool {
        return readKeychain(account: kUserPIN) != nil
    }
    
    func savePin(_ pin: String) {
        saveKeychain(data: pin.data(using: .utf8)!, account: kUserPIN)
        // After saving PIN, we are fully authenticated
        self.authState = .authenticated
    }
    
    func unlock(with pin: String) -> Bool {
        guard let storedPinData = KeychainHelper.standard.read(service: keychainService, account: kUserPIN),
              let storedPin = String(data: storedPinData, encoding: .utf8) else {
            return false
        }
        
        if pin == storedPin {
            self.authState = .authenticated
            return true
        }
        return false
    }
    
    func unlockWithBiometrics() {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Sblocca l'app per accedere ai tuoi dati"
            
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authenticationError in
                DispatchQueue.main.async {
                    if success {
                        self.authState = .authenticated
                    } else {
                        // Failed, stay locked (user can use PIN)
                        print("Biometric auth failed")
                    }
                }
            }
        }
    }
    
    func lockApp() {
        // Can only lock if we are authenticated or in PIN setup (though locking during PIN setup might be weird, usually we lock if we have a session)
        // Actually, if we are .unauthenticated, we stay there.
        // If we are .authenticated or .pinSetup (maybe?) or .locked, we go to .locked (if we have tokens).
        
        if getRefreshToken() != nil {
            self.authState = .locked
        } else {
            self.authState = .unauthenticated
        }
    }
    
    // MARK: - Auth Actions
    
    func login(username: String, password: String) async -> Bool {
        guard let url = URL(string: "\(baseURL)/login") else { return false }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: String] = ["username": username, "password": password]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        do {
            await MainActor.run { isLoading = true; errorMessage = nil }
            let (data, response) = try await URLSession.shared.data(for: request)
            await MainActor.run { isLoading = false }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                await MainActor.run { errorMessage = "Invalid response" }
                return false
            }
            
            if httpResponse.statusCode == 200 {
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let accessToken = json["accessToken"] as? String,
                   let refreshToken = json["refreshToken"] as? String {
                    
                    saveTokens(access: accessToken, refresh: refreshToken)
                    
                    await MainActor.run {
                        if hasPin() {
                            self.authState = .authenticated
                        } else {
                            self.authState = .pinSetup
                        }
                    }
                    return true
                } else if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                          let token = json["token"] as? String {
                     saveTokens(access: token, refresh: token)
                     await MainActor.run {
                         if hasPin() {
                             self.authState = .authenticated
                         } else {
                             self.authState = .pinSetup
                         }
                     }
                     return true
                }
            } else {
                await MainActor.run { errorMessage = "Login failed: \(httpResponse.statusCode)" }
            }
        } catch {
            await MainActor.run {
                isLoading = false
                errorMessage = error.localizedDescription
            }
        }
        return false
    }
    
    func register(username: String, password: String, email: String, name: String, surname: String) async -> Bool {
        guard let url = URL(string: "\(baseURL)/register") else { return false }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: String] = [
            "username": username,
            "password": password,
            "email": email,
            "name": name,
            "surname": surname
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        do {
            await MainActor.run { isLoading = true; errorMessage = nil }
            let (data, response) = try await URLSession.shared.data(for: request)
            await MainActor.run { isLoading = false }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                return false
            }
            
            if httpResponse.statusCode == 200 {
                // If register returns tokens, we could login immediately.
                // Assuming it works similar to login or just returns success.
                // For now, let's try to parse tokens too just in case.
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    if let accessToken = json["accessToken"] as? String,
                       let refreshToken = json["refreshToken"] as? String {
                        saveTokens(access: accessToken, refresh: refreshToken)
                        await MainActor.run { self.authState = .pinSetup } // Go to PIN setup
                    } else if let token = json["token"] as? String {
                        saveTokens(access: token, refresh: token)
                        await MainActor.run { self.authState = .pinSetup }
                    }
                }
                return true
            } else {
                await MainActor.run { errorMessage = "Registration failed" }
            }
        } catch {
            await MainActor.run { isLoading = false; errorMessage = error.localizedDescription }
        }
        return false
    }
    
    func logout() {
        clearTokens()
        // Keep PIN? Usually yes, for convenience next time, or logic says "UserPIN" is persistent.
        // User might want to clear PIN on logout though?
        // Spec says: "Logout: AuthManager cancella Access e Refresh token... Stato .unauthenticated".
        // Doesn't say delete PIN.
        DispatchQueue.main.async {
            self.authState = .unauthenticated
        }
    }
    
    // MARK: - Private Helpers
    
    private func readKeychain(account: String) -> String? {
        if let data = KeychainHelper.standard.read(service: keychainService, account: account) {
            return String(data: data, encoding: .utf8)
        }
        return nil
    }
    
    private func saveKeychain(data: Data, account: String) {
        KeychainHelper.standard.save(data, service: keychainService, account: account)
    }
    
    private func deleteKeychain(account: String) {
        KeychainHelper.standard.delete(service: keychainService, account: account)
    }
}
