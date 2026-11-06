import Foundation

nonisolated struct ProfileRepositoryLive: ProfileRepository {
    let client: APIClient

    func profile() async throws -> User {
        try await client.get(.profile)
    }
}
