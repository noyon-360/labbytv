import Foundation

/// Body for `POST /auth/login`. Mirrors Flutter `LoginRequestModel`.
nonisolated struct LoginRequest: Encodable, Sendable {
    let email: String
    let password: String
    let deviceId: String
}
