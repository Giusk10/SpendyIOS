import Foundation

struct LoginPayload: Codable {
    var username: String?
    var email: String?
    var password: String
}

struct RegisterPayload: Codable {
    var username: String
    var password: String
    var name: String
    var surname: String
    var email: String
}

struct LoginResponse: Codable {
    var token: String
}

struct User: Codable, Identifiable {
    var id: String?
    var username: String?
    var name: String?
    var surname: String?
    var email: String?
}
