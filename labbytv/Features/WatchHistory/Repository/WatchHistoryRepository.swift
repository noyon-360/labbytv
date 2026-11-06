import Foundation

nonisolated protocol WatchHistoryRepository: Sendable {
    func history(page: Int, limit: Int) async throws -> [WatchHistoryItem]
    func favorites(page: Int, limit: Int) async throws -> [WatchHistoryItem]
    func status(videoID: String) async throws -> VideoStatus
    func update(_ request: UpdateVideoStatusRequest) async throws
}
