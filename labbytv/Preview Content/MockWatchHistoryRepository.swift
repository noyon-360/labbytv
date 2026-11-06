#if DEBUG
import Foundation

nonisolated struct MockWatchHistoryRepository: WatchHistoryRepository {
    func history(page: Int, limit: Int) async throws -> [WatchHistoryItem] { MockData.historyItems }
    func favorites(page: Int, limit: Int) async throws -> [WatchHistoryItem] { MockData.historyItems.filter(\.isLoved) }
    func status(videoID: String) async throws -> VideoStatus { VideoStatus() }
    func update(_ request: UpdateVideoStatusRequest) async throws {}
}
#endif
