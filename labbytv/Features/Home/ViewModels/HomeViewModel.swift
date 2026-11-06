import Foundation
import Observation

/// Continue Watching + Popular Movies + Popular Series. "Popular" is the
/// first catalog page, de-duplicated by name, as in the Flutter home screen.
@MainActor
@Observable
final class HomeViewModel {
    private(set) var continueWatching: [ContinueWatchingItem] = []
    private(set) var movies: [Movie] = []
    private(set) var series: [Series] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    @ObservationIgnored private let catalog: any CatalogRepository
    @ObservationIgnored private let history: any WatchHistoryRepository
    @ObservationIgnored private let preferences: Preferences

    init(catalog: any CatalogRepository, history: any WatchHistoryRepository, preferences: Preferences) {
        self.catalog = catalog
        self.history = history
        self.preferences = preferences
    }

    var isEmpty: Bool { continueWatching.isEmpty && movies.isEmpty && series.isEmpty }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        async let historyTask = try? history.history(page: 1, limit: 30)
        async let moviesTask: [Movie] = catalog.items(.movies, categoryID: nil, search: nil, page: 1, limit: 30)
        async let seriesTask: [Series] = catalog.items(.series, categoryID: nil, search: nil, page: 1, limit: 30)

        var firstError: Error?
        do { movies = Self.uniqueByName(try await moviesTask) } catch { firstError = error }
        do { series = Self.uniqueByName(try await seriesTask) } catch { firstError = firstError ?? error }
        continueWatching = Self.continueWatching(from: await historyTask ?? [], preferences: preferences)

        if isEmpty, let firstError, !(firstError is CancellationError) {
            errorMessage = (firstError as? APIError)?.userMessage ?? APIError.unknown.userMessage
        }
    }

    /// Unfinished movies, plus episodes this TV knows the series for.
    static func continueWatching(from items: [WatchHistoryItem], preferences: Preferences) -> [ContinueWatchingItem] {
        items.compactMap { item in
            guard !item.isCompleted, item.currentTime > 0 else { return nil }
            switch item.videoType {
            case "movie":
                guard let id = item.streamID else { return nil }
                return ContinueWatchingItem(history: item, playable: .movie(id: id, title: item.name, thumbnail: item.thumbnail))
            case "series":
                guard let (episode, context) = preferences.episode(for: item.videoId) else { return nil }
                return ContinueWatchingItem(history: item, playable: .episode(episode, context: context))
            default:
                return nil
            }
        }
    }

    /// Keeps the first item per (case-insensitive) name, like Flutter `_uniqueByName`.
    nonisolated static func uniqueByName<Item: CatalogItem>(_ items: [Item]) -> [Item] {
        var seen = Set<String>()
        return items.filter { item in
            let key = item.title.trimmingCharacters(in: .whitespaces).lowercased()
            return key.isEmpty || seen.insert(key).inserted
        }
    }
}
