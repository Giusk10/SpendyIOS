import Foundation

class APIClient {
    static func performRequest<T: Decodable>(endpoint: String, method: String = "GET", body: Any? = nil, responseType: T.Type) async throws -> T {
        let url = URL(string: "\(Constants.baseURL)\(endpoint)")!
        var request = try await createRequest(url: url, method: method, body: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else { throw URLError(.badServerResponse) }
        
        // GESTIONE TOKEN SCADUTO (401)
        if httpResponse.statusCode == 401 {
            _ = try await AuthManager.shared.performRefresh() // Tenta refresh
            request = try await createRequest(url: url, method: method, body: body) // Riprova richiesta
            let (newData, newResponse) = try await URLSession.shared.data(for: request)
            
            if (newResponse as? HTTPURLResponse)?.statusCode == 401 {
                await AuthManager.shared.logout()
                throw URLError(.userAuthenticationRequired)
            }
            return try decode(data: newData, type: responseType)
        }
        
        guard (200...299).contains(httpResponse.statusCode) else { throw URLError(.badServerResponse) }
        return try decode(data: data, type: responseType)
    }
    
    static func performRequestNoResponse(endpoint: String, method: String = "GET", body: Any? = nil) async throws {
        let _: String = try await performRequest(endpoint: endpoint, method: method, body: body, responseType: String.self)
    }
    
    private static func createRequest(url: URL, method: String, body: Any?) async -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = await AuthManager.shared.getAccessToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        if let body = body { request.httpBody = try? JSONSerialization.data(withJSONObject: body) }
        return request
    }
    
    private static func decode<T: Decodable>(data: Data, type: T.Type) throws -> T {
        if data.isEmpty, let empty = "[]".data(using: .utf8), let res = try? JSONDecoder().decode(T.self, from: empty) { return res }
        return try JSONDecoder().decode(T.self, from: data)
    }
}
