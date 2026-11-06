import Foundation
import Observation

/// Favourites or watch history (both are watch-history records on the backend).
@MainActor
@Observable
final class FavoritesViewModel {
    enum Mode: Sendable {
        case favorites
        case history

        var title: String {
            switch self {
            case .favorites: "Favorites"
            case .history: "Watch History"
            }
        }
    }

    /// What selecting an entry does.
    enum Destination {
        case route(AppRoute)
        case play(PlayableItem)
        case unavailable
    }

    let mode: Mode
    private(set) var items: [WatchHistoryItem] = []
    private(set) var isLoading = false
    private(set) var isLoadingMore = false
    private(set) var errorMessage: String?

    @ObservationIgnored private let repository: any WatchHistoryRepository
    @ObservationIgnored private let preferences: Preferences
    @ObservationIgnored private var page = 1
    @ObservationIgnored private var hasMore = true
    private static let pageSize = 30

    init(mode: Mode, repository: any WatchHistoryRepository, preferences: Preferences) {
        self.mode = mode
        self.repository = repository
        self.preferences = preferences
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        page = 1
        hasMore = true
        do {
            let list = try await fetch(page: 1)
            items = list
            hasMore = list.count >= Self.pageSize
            page = 2
        } catch is CancellationError {
            return
        } catch {
            errorMessage = (error as? APIError)?.userMessage ?? APIError.unknown.userMessage
        }
    }

    func loadMoreIfNeeded(after item: WatchHistoryItem) async {
        guard hasMore, !isLoadingMore, items.last?.id == item.id else { return }
        isLoadingMore = true
        defer { isLoadingMore = false }
        guard let list = try? await fetch(page: page) else { return }
        let existing = Set(items.map(\.id))
        items += list.filter { !existing.contains($0.id) }
        hasMore = list.count >= Self.pageSize
        page += 1
    }

    func destination(for item: WatchHistoryItem) -> Destination {
        switch item.videoType {
        case "live":
            guard let id = item.streamID else { return .unavailable }
            let channel = Channel(id: id, name: item.name, streamIcon: item.thumbnail)
            return .play(.live(channel, lineup: [channel]))
        case "movie":
            guard let id = item.streamID else { return .unavailable }
            return .route(.movie(Movie(id: id, name: item.name, streamIcon: item.thumbnail)))
        case "series":
            // Show-level records (favourites) hold the series id; episode
            // records hold the episode id, which only this TV can map back.
            if item.seasonNumber == nil, let id = item.streamID {
                return .route(.series(Series(id: id, name: item.name, cover: item.thumbnail)))
            }
            if let (episode, context) = preferences.episode(for: item.videoId) {
                return .play(.episode(episode, context: context))
            }
            return .unavailable
        default:
            return .unavailable
        }
    }

    private func fetch(page: Int) async throws -> [WatchHistoryItem] {
        switch mode {
        case .favorites: try await repository.favorites(page: page, limit: Self.pageSize)
        case .history: try await repository.history(page: page, limit: Self.pageSize)
        }
    }
}
