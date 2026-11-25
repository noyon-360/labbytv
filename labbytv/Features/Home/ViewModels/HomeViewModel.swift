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
    /// False until the first `load()` finishes. Without it the view renders the
    /// empty state for the frames before `.task` starts the first fetch.
    private(set) var hasLoaded = false

    @ObservationIgnored private let catalog: any CatalogRepository
    @ObservationIgnored private let history: any WatchHistoryRepository
    @ObservationIgnored private let preferences: Preferences
    @ObservationIgnored private let parentalLock: ParentalLockService?
    @ObservationIgnored private var seenLockChange = 0
    @ObservationIgnored private var seenLockReveal = 0
    /// Overlapping loads (first appearance + player close) must not let the
    /// older one clear `isLoading` while the newer is still fetching.
    @ObservationIgnored private var generation = 0

    init(catalog: any CatalogRepository, history: any WatchHistoryRepository, preferences: Preferences, parentalLock: ParentalLockService? = nil) {
        self.catalog = catalog
        self.history = history
        self.preferences = preferences
        self.parentalLock = parentalLock
        seenLockChange = parentalLock?.changeCount ?? 0
        seenLockReveal = parentalLock?.revealCount ?? 0
    }

    /// Observed by the view so lock changes apply while Home is on screen.
    var parentalLockChangeCount: Int { parentalLock?.changeCount ?? 0 }

    /// Locked categories stay out of the shelves (Flutter: "hidden from All,
    /// Home and Search"). Revealing needs a reload; hiding only a filter.
    func applyParentalLockChanges() async {
        guard let parentalLock, parentalLock.changeCount != seenLockChange else { return }
        let reveals = parentalLock.revealCount != seenLockReveal
        seenLockChange = parentalLock.changeCount
        seenLockReveal = parentalLock.revealCount
        guard hasLoaded else { return }
        if reveals {
            await load()
        } else {
            movies = movies.filter { !parentalLock.isHidden(.movies, categoryID: $0.categoryId) }
            series = series.filter { !parentalLock.isHidden(.series, categoryID: $0.categoryId) }
        }
    }

    var isEmpty: Bool { continueWatching.isEmpty && movies.isEmpty && series.isEmpty }

    func load() async {
        generation += 1
        let current = generation
        isLoading = true
        errorMessage = nil

        async let historyTask = try? history.history(page: 1, limit: 30)
        async let moviesTask: [Movie] = catalog.items(.movies, categoryID: nil, search: nil, page: 1, limit: 30)
        async let seriesTask: [Series] = catalog.items(.series, categoryID: nil, search: nil, page: 1, limit: 30)

        let movieResult: Result<[Movie], any Error>
        do { movieResult = .success(try await moviesTask) } catch { movieResult = .failure(error) }
        let seriesResult: Result<[Series], any Error>
        do { seriesResult = .success(try await seriesTask) } catch { seriesResult = .failure(error) }
        let historyItems = await historyTask

        // A newer load (player closed, lock revealed) owns the state now.
        guard current == generation else { return }
        // The sidebar TabView can cancel Home's `.task` while the first fetch
        // is still in flight. Treating that as "finished, nothing found" showed
        // the empty state; instead keep the loader up and let the next
        // appearance retry, without wiping shelves an earlier load filled.
        if Task.isCancelled || Self.isCancellation(movieResult) || Self.isCancellation(seriesResult) {
            isLoading = false
            return
        }

        var firstError: Error?
        switch movieResult {
        case .success(let items): movies = Self.uniqueByName(visible(items, .movies))
        case .failure(let error): firstError = error
        }
        switch seriesResult {
        case .success(let items): series = Self.uniqueByName(visible(items, .series))
        case .failure(let error): firstError = firstError ?? error
        }
        continueWatching = Self.continueWatching(from: historyItems ?? [], preferences: preferences)

        if isEmpty, let firstError {
            errorMessage = (firstError as? APIError)?.userMessage ?? APIError.unknown.userMessage
        }
        isLoading = false
        hasLoaded = true
    }

    private static func isCancellation<T>(_ result: Result<T, any Error>) -> Bool {
        if case .failure(let error) = result { return error is CancellationError }
        return false
    }

    private func visible<Item: CatalogItem>(_ items: [Item], _ type: ContentType) -> [Item] {
        guard let parentalLock else { return items }
        return items.filter { !parentalLock.isHidden(type, categoryID: $0.categoryId) }
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
