import Foundation
import SwiftUI
import Combine

class AuthManager: ObservableObject {
    static let shared = AuthManager()
    
    @Published var isAuthenticated: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let baseURL = "http://100.117.226.152:8080/Auth/auth"
    private let keychainService = "com.appios.auth"
    private let keychainAccount = "accessToken"
    
    private init() {
        self.isAuthenticated = getToken() != nil
    }
    
    func getToken() -> String? {
        if let data = KeychainHelper.standard.read(service: keychainService, account: keychainAccount) {
            return String(data: data, encoding: .utf8)
        }
        return nil
    }
    
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
                // Parse token
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let token = json["token"] as? String {
                    saveToken(token)
                    await MainActor.run { isAuthenticated = true }
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
                // Assuming register returns token too, or just success. 
                // If it returns token, save it. checking response...
                // Spec says: Registrazione: POST /Auth/auth/register ...
                // Doesn't explicitly say it returns token, but usually it does or user logs in. 
                // I'll assume for now we might need to login after register or if it returns token I'll save it.
                // Let's check if there is a token in response just in case
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let token = json["token"] as? String {
                    saveToken(token)
                    await MainActor.run { isAuthenticated = true }
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
        KeychainHelper.standard.delete(service: keychainService, account: keychainAccount)
        DispatchQueue.main.async {
            self.isAuthenticated = false
        }
    }
    
    private func saveToken(_ token: String) {
        if let data = token.data(using: .utf8) {
            KeychainHelper.standard.save(data, service: keychainService, account: keychainAccount)
        }
    }
}
