import Foundation
import Observation
import os

/// Favourite channels. Stored on the backend as watch-history records with
/// `videoType: "live"` and `isLoved: true` (same as the phone apps), so they
/// survive reinstalls and show on every device.
@MainActor
@Observable
final class ChannelFavorites {
    /// Newest first, as the backend sorts them.
    private(set) var channels: [Channel] = []
    private(set) var isLoaded = false
    /// Bumped on every change, so screens showing the Favorites category
    /// know to refresh.
    private(set) var changeCount = 0

    @ObservationIgnored private let repository: any WatchHistoryRepository
    @ObservationIgnored private var loadTask: Task<Void, Never>?

    /// `/favorites` has no type filter, so movies and series come back too;
    /// page through all of them and keep the live ones.
    private static let pageSize = 100
    private static let maxPages = 10

    init(repository: any WatchHistoryRepository) {
        self.repository = repository
    }

    func isFavorite(_ channelID: Int) -> Bool {
        channels.contains { $0.id == channelID }
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

    /// Optimistic: the heart flips at once and flips back if the call fails.
    func toggle(_ channel: Channel) async {
        let wasFavorite = isFavorite(channel.id)
        apply(channel, favorite: !wasFavorite)

        var request = UpdateVideoStatusRequest(title: channel.name.isEmpty ? "Live TV" : channel.name, videoId: String(channel.id), videoType: "live")
        request.isLoved = !wasFavorite
        request.thumbnail = channel.streamIcon.isEmpty ? nil : channel.streamIcon
        do {
            try await repository.update(request)
        } catch {
            Logger.network.error("Favourite channel update failed: \(String(describing: error), privacy: .public)")
            apply(channel, favorite: wasFavorite)
        }
    }

    func reset() {
        channels = []
        isLoaded = false
        changeCount += 1
    }

    private func apply(_ channel: Channel, favorite: Bool) {
        channels.removeAll { $0.id == channel.id }
        if favorite { channels.insert(channel, at: 0) }
        changeCount += 1
    }

    private func load() async {
        var collected: [WatchHistoryItem] = []
        do {
            for page in 1...Self.maxPages {
                let list = try await repository.favorites(page: page, limit: Self.pageSize)
                collected += list
                if list.count < Self.pageSize { break }
            }
        } catch {
            // Keep what's known; the next screen that needs favourites retries.
            return
        }
        channels = Self.channels(from: collected)
        isLoaded = true
        changeCount += 1
    }

    nonisolated static func channels(from items: [WatchHistoryItem]) -> [Channel] {
        var seen = Set<Int>()
        return items.compactMap { item in
            guard item.videoType == "live", item.isLoved, let id = item.streamID, seen.insert(id).inserted else { return nil }
            return Channel(id: id, name: item.name, streamIcon: item.thumbnail)
        }
    }
}
