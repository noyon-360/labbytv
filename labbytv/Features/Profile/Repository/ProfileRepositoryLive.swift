import Foundation

nonisolated struct ProfileRepositoryLive: ProfileRepository {
    let client: APIClient

    func profile() async throws -> User {
        try await client.get(.profile)
    }

    func verifyPassword(_ password: String) async throws -> Bool {
        let check: PasswordCheck = try await client.post(.verifyPassword, body: VerifyPasswordRequest(password: password))
        return check.valid
    }
}
