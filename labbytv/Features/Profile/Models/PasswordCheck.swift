import Foundation

/// `data` of `/user/verify-password`: `{ valid: Bool }`.
nonisolated struct PasswordCheck: Decodable, Sendable {
    let valid: Bool
}
