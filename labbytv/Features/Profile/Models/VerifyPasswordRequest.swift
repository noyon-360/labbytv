import Foundation

/// Body of `/user/verify-password` (Flutter `ParentalLockService._checkAccountPassword`).
nonisolated struct VerifyPasswordRequest: Encodable, Sendable {
    let password: String
}
