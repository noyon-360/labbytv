import Foundation

nonisolated protocol ProfileRepository: Sendable {
    func profile() async throws -> User
    /// True when `password` is the signed-in account's password.
    func verifyPassword(_ password: String) async throws -> Bool
}
