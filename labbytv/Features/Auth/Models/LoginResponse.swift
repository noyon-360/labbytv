import Foundation

/// `data` of `POST /auth/login`. Mirrors Flutter `LoginData`.
nonisolated struct LoginResponse: Decodable, Sendable {
    let accessToken: String?
    let refreshToken: String?
    let role: String?
    let id: String?
    let user: User?

    private enum CodingKeys: String, CodingKey {
        case accessToken, refreshToken, role, user
        case id = "_id"
    }
}
