import Foundation

/// Body for `/auth/register`. Mirrors Flutter `RegisterRequestModel`.
nonisolated struct RegisterRequest: Encodable, Sendable {
    let name: String
    let email: String
    let password: String
    let confirmPassword: String
}
