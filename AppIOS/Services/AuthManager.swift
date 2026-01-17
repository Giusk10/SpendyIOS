import Foundation
import LocalAuthentication
import SwiftUI
import Combine

@MainActor
class AuthManager: ObservableObject {
    static let shared = AuthManager()
    
    // Stati per la UI
    @Published var isAuthenticated: Bool = false
    @Published var isLocked: Bool = true
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // Chiavi Keychain
    private let service = "com.appios.auth"
    private let accessKey = "accessToken"
    private let refreshKey = "refreshToken"
    
    private init() {
        // Se esiste il refresh token, l'utente è loggato ma l'app parte bloccata
        if KeychainHelper.standard.read(service: service, account: refreshKey) != nil {
            self.isAuthenticated = true
            self.isLocked = true
        }
    }
    
    // MARK: - Getters Token
    func getAccessToken() -> String? {
        guard let data = KeychainHelper.standard.read(service: service, account: accessKey) else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    func getRefreshToken() -> String? {
        guard let data = KeychainHelper.standard.read(service: service, account: refreshKey) else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    // MARK: - Login (Parametri allineati alla tua AuthView)
    func login(username: String, password: String) async -> Bool { // Parametro 'password' corretto
        isLoading = true; errorMessage = nil
        let url = URL(string: "\(Constants.baseURL)/Auth/rest/auth/login")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: ["username": username, "password": password])
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            isLoading = false
            guard (response as? HTTPURLResponse)?.statusCode == 200 else {
                errorMessage = "Credenziali non valide"; return false
            }
            return try handleAuthResponse(data: data)
        } catch {
            isLoading = false; errorMessage = error.localizedDescription; return false
        }
    }
    
    // MARK: - Register
    func register(username: String, password: String, email: String, name: String, surname: String) async -> Bool {
        isLoading = true; errorMessage = nil
        let url = URL(string: "\(Constants.baseURL)/Auth/rest/auth/register")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body = ["username": username, "password": password, "email": email, "name": name, "surname": surname]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            isLoading = false
            guard let httpResponse = response as? HTTPURLResponse else { return false }
            
            if httpResponse.statusCode == 200 {
                // Se il server torna i token, login automatico
                if let _ = try? handleAuthResponse(data: data) { return true }
                return true
            } else if httpResponse.statusCode == 409 {
                errorMessage = "Utente già esistente"
            } else {
                errorMessage = "Errore durante la registrazione"
            }
        } catch {
            isLoading = false; errorMessage = error.localizedDescription
        }
        return false
    }
    
    // MARK: - Refresh & Logout
    func performRefresh() async throws -> String {
        guard let refreshToken = getRefreshToken() else { throw URLError(.userAuthenticationRequired) }
        
        let url = URL(string: "\(Constants.baseURL)/Auth/rest/auth/refresh")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: ["refreshToken": refreshToken])
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if (response as? HTTPURLResponse)?.statusCode == 200 {
            _ = try handleAuthResponse(data: data)
            if let newAccess = getAccessToken() { return newAccess }
        }
        
        logout()
        throw URLError(.userAuthenticationRequired)
    }
    
    func logout() {
        KeychainHelper.standard.delete(service: service, account: accessKey)
        KeychainHelper.standard.delete(service: service, account: refreshKey)
        withAnimation { isAuthenticated = false; isLocked = false }
    }
    
    func unlockWithBiometrics() {
        let context = LAContext()
        var error: NSError?
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "Sblocca Spendy") { success, _ in
                Task { @MainActor in if success { withAnimation { self.isLocked = false } } }
            }
        } else { withAnimation { self.isLocked = false } }
    }
    
    private func handleAuthResponse(data: Data) throws -> Bool {
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let access = json["accessToken"] as? String,
           let refresh = json["refreshToken"] as? String {
            
            if let accData = access.data(using: .utf8) { KeychainHelper.standard.save(accData, service: service, account: accessKey) }
            if let refData = refresh.data(using: .utf8) { KeychainHelper.standard.save(refData, service: service, account: refreshKey) }
            
            withAnimation { isAuthenticated = true; isLocked = false }
            return true
        }
        return false
    }
}
