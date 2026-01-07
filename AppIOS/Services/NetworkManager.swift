import Foundation
import Combine

class NetworkManager {
    static let shared = NetworkManager()
    private init() {}
    
    private let baseURL = "http://100.117.226.152:8080"
    
    func performRequest<T: Decodable>(endpoint: String, method: String = "GET", body: Data? = nil, responseType: T.Type) async throws -> T {
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = AuthManager.shared.getToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        if let body = body {
            request.httpBody = body
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        if httpResponse.statusCode == 401 {
            AuthManager.shared.logout()
            throw URLError(.userAuthenticationRequired)
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            // Try to parse error message if possible, or just throw
            throw URLError(.badServerResponse)
        }
        
        // If expecting Void (empty response), return empty T (hacky but works for generic T)
        if responseType == String.self, data.isEmpty {
             return "" as! T
        }
        
        let decoder = JSONDecoder()
        // Handle date strategies if needed. For now assuming string or ISO8601
        
        return try decoder.decode(T.self, from: data)
    }
    
    // For calls that don't return data (like DELETE)
    func performRequestNoResponse(endpoint: String, method: String = "GET", body: Data? = nil) async throws {
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = AuthManager.shared.getToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        if let body = body {
            request.httpBody = body
        }
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        if httpResponse.statusCode == 401 {
            AuthManager.shared.logout()
            throw URLError(.userAuthenticationRequired)
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
    }
    
    // For Multipart Upload
    func uploadFile(endpoint: String, fileURL: URL) async throws -> Bool {
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
             return false
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        if let token = AuthManager.shared.getToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        var data = Data()
        guard let fileData = try? Data(contentsOf: fileURL) else { return false }
        
        data.append("--\(boundary)\r\n".data(using: .utf8)!)
        data.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileURL.lastPathComponent)\"\r\n".data(using: .utf8)!)
        data.append("Content-Type: text/csv\r\n\r\n".data(using: .utf8)!)
        data.append(fileData)
        data.append("\r\n".data(using: .utf8)!)
        data.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = data
        
        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else { return false }
        
        if httpResponse.statusCode == 401 {
            AuthManager.shared.logout()
            return false
        }
        
        return (200...299).contains(httpResponse.statusCode)
    }
}
