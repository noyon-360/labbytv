#if DEBUG
import Foundation

nonisolated struct MockProfileRepository: ProfileRepository {
    func profile() async throws -> User { MockData.user }
}
#endif
