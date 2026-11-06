#if DEBUG
import Foundation

nonisolated struct MockEPGRepository: EPGRepository {
    func schedule(channelID: Int, from: Date, to: Date) async throws -> [EPGProgram] {
        MockData.programs.filter { $0.end > from && $0.start < to }
    }
}
#endif
