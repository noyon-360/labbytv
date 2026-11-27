#if DEBUG
import Foundation

/// In-memory My List, so previews and the `-UITestMockData` run can add and
/// remove titles.
actor MockWatchLaterRepository: WatchLaterRepository {
    private var items: [WatchLaterItem]

    init(items: [WatchLaterItem] = MockData.watchLaterItems) {
        self.items = items
    }

    func list(page: Int, limit: Int) async throws -> [WatchLaterItem] {
        page == 1 ? Array(items.prefix(limit)) : []
    }

    func status(videoType: String, videoID: String) async throws -> WatchLaterStatus {
        let item = items.first { $0.videoType == videoType && $0.videoId == videoID }
        return WatchLaterStatus(isSaved: item != nil, id: item?.id)
    }

    func add(videoType: String, videoID: String, title: String, thumbnail: String?) async throws -> WatchLaterItem {
        if let existing = items.first(where: { $0.videoType == videoType && $0.videoId == videoID }) { return existing }
        let item = WatchLaterItem(id: UUID().uuidString, videoType: videoType, videoId: videoID, title: title, thumbnail: thumbnail ?? "")
        items.insert(item, at: 0)
        return item
    }

    func remove(id: String) async throws {
        items.removeAll { $0.id == id }
    }
}
#endif
