import Foundation

nonisolated protocol EPGRepository: Sendable {
    /// Every programme for one channel overlapping `from..<to`.
    func schedule(channelID: Int, from: Date, to: Date) async throws -> [EPGProgram]
}
