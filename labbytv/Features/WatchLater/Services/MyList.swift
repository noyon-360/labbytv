import Foundation
import Observation
import os

/// "My List" (backend watch later) for the active playlist and profile.
/// Shared by the Home row and the detail pages, so adding a title on its
/// page shows up on Home without a reload.
@MainActor
@Observable
final class MyList {
    /// Newest first, as the backend sorts them. Only the first page: Home
    /// shows a row, not the whole list.
    private(set) var items: [WatchLaterItem] = []
    private(set) var isLoaded = false

    @ObservationIgnored private let repository: any WatchLaterRepository
    @ObservationIgnored private var loadTask: Task<Void, Never>?
    static let pageSize = 50

    init(repository: any WatchLaterRepository) {
        self.repository = repository
    }

    func loadIfNeeded() async {
        if isLoaded { return }
        if let loadTask { return await loadTask.value }
        let task = Task { await self.load() }
        loadTask = task
        await task.value
        loadTask = nil
    }

    func reload() async {
        isLoaded = false
        await loadIfNeeded()
    }

    /// Asks the backend, because the title may be past the first page.
    func status(videoType: String, videoID: String) async -> WatchLaterStatus? {
        if let item = items.first(where: { $0.videoType == videoType && $0.videoId == videoID }) {
            return WatchLaterStatus(isSaved: true, id: item.id)
        }
        return try? await repository.status(videoType: videoType, videoID: videoID)
    }

    /// Returns the saved item's id, or `nil` when the call failed.
    func add(videoType: String, videoID: String, title: String, thumbnail: String?) async -> String? {
        do {
            let item = try await repository.add(videoType: videoType, videoID: videoID, title: title, thumbnail: thumbnail)
            items.removeAll { $0.id == item.id }
            items.insert(item, at: 0)
            return item.id
        } catch {
            Logger.network.error("My List add failed: \(String(describing: error), privacy: .public)")
            return nil
        }
    }

    /// `true` when it's gone (a 404 means it already was).
    func remove(id: String) async -> Bool {
        do {
            try await repository.remove(id: id)
        } catch APIError.server(status: 404, _) {
            // Removed on another device; treat as done.
        } catch {
            Logger.network.error("My List remove failed: \(String(describing: error), privacy: .public)")
            return false
        }
        items.removeAll { $0.id == id }
        return true
    }

    func reset() {
        items = []
        isLoaded = false
    }

    private func load() async {
        guard let list = try? await repository.list(page: 1, limit: Self.pageSize) else { return }
        items = list
        isLoaded = true
    }
}
