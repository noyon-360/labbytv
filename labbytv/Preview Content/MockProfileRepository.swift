#if DEBUG
import Foundation

nonisolated struct MockProfileRepository: ProfileRepository {
    /// The password `verifyPassword` accepts.
    var accountPassword = "password"

    func profile() async throws -> User { MockData.user }

    func verifyPassword(_ password: String) async throws -> Bool {
        password == accountPassword
    }
}
#endif
