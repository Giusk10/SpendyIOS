import Foundation

struct AuthService {
    static let shared = AuthService()
    private init() {}
    
    func login(payload: LoginPayload) async throws -> LoginResponse {
        return try await HTTPClient.shared.request(endpoint: "/Auth/rest/auth/login", method: "POST", body: payload)
    }
    
    func register(payload: RegisterPayload) async throws -> String {
        return try await HTTPClient.shared.request(endpoint: "/Auth/rest/auth/register", method: "POST", body: payload)
    }
    
    func linkHouse(houseCode: String) async throws -> LinkHouseResponse {
        struct LinkHousePayload: Encodable { let houseCode: String }
        return try await HTTPClient.shared.request(endpoint: "/Auth/rest/auth/external/link-house", method: "POST", body: LinkHousePayload(houseCode: houseCode))
    }
    
    func getCoinquilini(houseId: String) async throws -> [User] {
        // Need to handle query params in HTTPClient or manually construct URL here
        // For simplicity, appending query param manually as generic client is basic
        return try await HTTPClient.shared.request(endpoint: "/Auth/rest/client/retrieveCoinquy?houseId=\(houseId)", method: "GET")
    }
}

struct LinkHouseResponse: Codable {
    var message: String
}
