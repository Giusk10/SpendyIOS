import Foundation

@MainActor
class NetworkManager {
    static let shared = NetworkManager()
    
    // Using a Task to handle refresh concurrency
    private var refreshTask: Task<Bool, Never>?
    
    private init() {}
    
    private let authBaseURL = "\(Constants.baseURL)/Auth/rest/auth"
    
    // MARK: - Generic Request
    
    func performRequest<T: Decodable>(url: URL, method: String = "GET", body: Any? = nil, responseType: T.Type) async throws -> T {
        // 1. Prepare Request with current token
        let request = try prepareRequest(url: url, method: method, body: body)
        
        print("🚀 [REQUEST] \(method) \(url.absoluteString)")
        if let body = body {
             print("📦 [BODY] \(body)")
        }
        
        // 2. Perform Request
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // 3. Handle 401 -> Refresh Flow
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 401 {
                print("⚠️ 401 Detected. Attempting Refresh...")
                
                let refreshed = await handleTokenRefresh()
                
                if refreshed {
                    // Retry with new token
                    print("✅ Token Refreshed. Retrying request...")
                    let newRequest = try prepareRequest(url: url, method: method, body: body)
                    let (newData, newResponse) = try await URLSession.shared.data(for: newRequest)
                    return try handleResponse(data: newData, response: newResponse, responseType: responseType)
                } else {
                    // Refresh failed -> Logout
                    print("⛔️ Refresh Failed. Logging out.")
                    AuthManager.shared.logout()
                    throw URLError(.userAuthenticationRequired)
                }
            }
            
            // 4. Handle Normal Response
            return try handleResponse(data: data, response: response, responseType: responseType)
            
        } catch {
            print("❌ [FAILURE] Request failed: \(error.localizedDescription)")
            throw error
        }
    }
    
    // Helper for Void/NoResponse requests
    func performRequestNoResponse(url: URL, method: String = "GET", body: Any? = nil) async throws {
        _ = try await performRequest(url: url, method: method, body: body, responseType: String.self) // Dummy type, ignored
    }
    
    // MARK: - Request Preparation
    
    private func prepareRequest(url: URL, method: String, body: Any?) throws -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Inject Access Token
        if let token = AuthManager.shared.getAccessToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        if let body = body {
            request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        }
        
        return request
    }
    
    // MARK: - Response Handling
    
    private func handleResponse<T: Decodable>(data: Data, response: URLResponse, responseType: T.Type) throws -> T {
        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ [ERROR] Invalid Response Type")
            throw URLError(.badServerResponse)
        }
        
        print("📥 [RESPONSE] \(httpResponse.statusCode) from \(httpResponse.url?.absoluteString ?? "unknown")")
        // Optional: print("📄 [DATA] \(String(data: data, encoding: .utf8) ?? "Unable to decode data")")
        
        guard (200...299).contains(httpResponse.statusCode) else {
            // Also handle 401 here if it wasn't caught above?
            // Actually above logic only catches 401 if it happens.
            // If we are here, status is NOT 401 (unless logic failure), so we check success.
            if httpResponse.statusCode == 401 {
               throw URLError(.userAuthenticationRequired)
            }
            throw URLError(.badServerResponse)
        }
        
        // Handle String Response (JSON or Plain Text)
        if responseType == String.self {
            if data.isEmpty {
                return "" as! T
            }
            // Try standard JSON decoding first (e.g. "some string")
            if let decodedState = try? JSONDecoder().decode(T.self, from: data) {
                return decodedState
            }
            // Fallback: Treat as plain text
            if let plainText = String(data: data, encoding: .utf8) as? T {
                return plainText
            }
        }
        
        // Handle 204 No Content with expected array
        if httpResponse.statusCode == 204, data.isEmpty {
            // Check if T is an Array
            // This is a bit hacky in Swift generic check, assuming valid empty JSON "[]" works for array types
            if let emptyList = try? JSONDecoder().decode(T.self, from: "[]".data(using: .utf8)!) {
                return emptyList
            }
        }

        return try JSONDecoder().decode(T.self, from: data)
    }
    
    // MARK: - Token Refresh Logic
    
    private func handleTokenRefresh() async -> Bool {
        // Debounce: If a refresh is already in progress, wait for it.
        if let task = refreshTask {
             return await task.value
        }
        
        // Start new refresh task
        let task = Task { () -> Bool in
            defer { refreshTask = nil } // Cleanup when done
            
            guard let refreshToken = AuthManager.shared.getRefreshToken() else {
                return false
            }
            
            guard let url = URL(string: "\(authBaseURL)/refresh") else { return false }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("Bearer \(refreshToken)", forHTTPHeaderField: "Authorization") // Some APIs want it in Body or Header??
            // Spec says "inviando il RefreshToken". Usually Bearer or Body.
            // "NetworkManager sostituisce l'header Authorization con il nuovo token" implies Authorization header is used for requests.
            // For /refresh, we usually send RefreshToken in body or header. 
            // Let's assume Body for safety or Standard Oauth uses body `grant_type=refresh_token`.
            // BUT, current backend might expect it in Header?
            // Looking at AuthManager login, it returns Map.
            // Let's try sending in Header as Bearer (common for some JWT impls) OR Body.
            // Java Spring Security often looks at Header.
            // Let's assume Header "Bearer <refreshToken>" for the refresh endpoint.
            
            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                
                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                    return false
                }
                
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let newAccessToken = json["accessToken"] as? String,
                   let newRefreshToken = json["refreshToken"] as? String {
                    
                    AuthManager.shared.saveTokens(access: newAccessToken, refresh: newRefreshToken)
                    return true
                }
                 // Fallback if keys are different or wrapped
                 if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let token = json["token"] as? String {
                     AuthManager.shared.saveTokens(access: token, refresh: token)
                     return true
                 }
                
                return false
            } catch {
                return false
            }
        }
        
        self.refreshTask = task
        return await task.value
    }
}
