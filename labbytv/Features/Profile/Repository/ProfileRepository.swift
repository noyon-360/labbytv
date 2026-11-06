import Foundation

nonisolated protocol ProfileRepository: Sendable {
    func profile() async throws -> User
}
