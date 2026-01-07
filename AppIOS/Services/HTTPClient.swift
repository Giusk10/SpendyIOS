import Foundation

enum HTTPError: Error {
    case invalidURL
    case noData
    case decodingError
    case serverError(String)
    case unauthorized
}

class HTTPClient {
    static let shared = HTTPClient()
    private init() {}
    
    private var token: String?
    
    func setToken(_ token: String) {
        self.token = token
    }
    
    func clearToken() {
        self.token = nil
    }
    
    func request<T: Decodable>(endpoint: String, method: String = "GET", body: Encodable? = nil) async throws -> T {
        guard let url = URL(string: "\(Constants.baseURL)\(endpoint)") else {
            throw HTTPError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        if let body = body {
            request.httpBody = try JSONEncoder().encode(body)
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw HTTPError.serverError("Invalid response")
        }
        
        if !(200...299).contains(httpResponse.statusCode) {
             if httpResponse.statusCode == 401 {
                throw HTTPError.unauthorized
            }
            if let errorMessage = String(data: data, encoding: .utf8) {
                 throw HTTPError.serverError(errorMessage)
            }
            throw HTTPError.serverError("Status code: \(httpResponse.statusCode)")
        }
        
        // Handle empty response for void returns or specific cases if needed
        if T.self == String.self {
             if let stringData = String(data: data, encoding: .utf8) {
                 return stringData as! T
             }
        }

        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            print("Decoding error: \(error)")
            throw HTTPError.decodingError
        }
    }
    
    // Helper for non-JSON response (like plain string token sometimes) or empty
    func requestEmpty(endpoint: String, method: String = "GET", body: Encodable? = nil) async throws {
         guard let url = URL(string: "\(Constants.baseURL)\(endpoint)") else {
            throw HTTPError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        if let body = body {
            request.httpBody = try JSONEncoder().encode(body)
        }
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw HTTPError.serverError("Invalid response")
        }
        
        if !(200...299).contains(httpResponse.statusCode) {
             if httpResponse.statusCode == 401 {
                throw HTTPError.unauthorized
            }
            throw HTTPError.serverError("Status code: \(httpResponse.statusCode)")
        }
    }
}
