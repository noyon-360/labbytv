import Foundation
import Observation

/// Home rows, in the Flutter TV order: Favorite Channels, Continue Watching,
/// Recently Watched, Popular Movies, Popular Series, Recently Added Movies,
/// Recently Added TV Shows, My List. "Popular" is the first catalog page,
/// de-duplicated by name, as in the Flutter home screen.
@MainActor
@Observable
final class HomeViewModel {
    private(set) var continueWatching: [ContinueWatchingItem] = []
    private(set) var movies: [Movie] = []
    private(set) var series: [Series] = []
    private(set) var recentlyWatched: [WatchHistoryItem] = []
    private(set) var recentlyAddedMovies: [Movie] = []
    private(set) var recentlyAddedSeries: [Series] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?
    /// False until the first `load()` finishes. Without it the view renders the
    /// empty state for the frames before `.task` starts the first fetch.
    private(set) var hasLoaded = false

    @ObservationIgnored private let catalog: any CatalogRepository
    @ObservationIgnored private let history: any WatchHistoryRepository
    @ObservationIgnored private let preferences: Preferences
    @ObservationIgnored private let parentalLock: ParentalLockService?
    @ObservationIgnored private let channelFavorites: ChannelFavorites?
    @ObservationIgnored private let myList: MyList?
    @ObservationIgnored private var seenLockChange = 0
    @ObservationIgnored private var seenLockReveal = 0
    /// Overlapping loads (first appearance + player close) must not let the
    /// older one clear `isLoading` while the newer is still fetching.
    @ObservationIgnored private var generation = 0

    init(
        catalog: any CatalogRepository,
        history: any WatchHistoryRepository,
        preferences: Preferences,
        parentalLock: ParentalLockService? = nil,
        channelFavorites: ChannelFavorites? = nil,
        myList: MyList? = nil
    ) {
        self.catalog = catalog
        self.history = history
        self.preferences = preferences
        self.parentalLock = parentalLock
        self.channelFavorites = channelFavorites
        self.myList = myList
        seenLockChange = parentalLock?.changeCount ?? 0
        seenLockReveal = parentalLock?.revealCount ?? 0
    }

    /// Observed by the view so lock changes apply while Home is on screen.
    var parentalLockChangeCount: Int { parentalLock?.changeCount ?? 0 }

    /// Read from the shared stores, so a heart or My List change elsewhere
    /// shows here without a reload.
    var favoriteChannels: [Channel] { channelFavorites?.channels ?? [] }
    var myListItems: [WatchLaterItem] { myList?.items.filter { $0.route != nil } ?? [] }

    func destination(for item: WatchHistoryItem) -> FavoritesViewModel.Destination {
        FavoritesViewModel.destination(for: item, preferences: preferences)
    }

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
            recentlyAddedMovies = recentlyAddedMovies.filter { !parentalLock.isHidden(.movies, categoryID: $0.categoryId) }
            recentlyAddedSeries = recentlyAddedSeries.filter { !parentalLock.isHidden(.series, categoryID: $0.categoryId) }
        }
    }

    var isEmpty: Bool {
        continueWatching.isEmpty && movies.isEmpty && series.isEmpty && recentlyWatched.isEmpty
            && favoriteChannels.isEmpty && myListItems.isEmpty
    }

    func load() async {
        generation += 1
        let current = generation
        isLoading = true
        errorMessage = nil

        async let historyTask = try? history.history(page: 1, limit: 30)
        // A bigger page than Popular shows, so Recently Added has more to pick from.
        async let moviesTask: [Movie] = catalog.items(.movies, categoryID: nil, search: nil, page: 1, limit: Self.catalogPage)
        async let seriesTask: [Series] = catalog.items(.series, categoryID: nil, search: nil, page: 1, limit: Self.catalogPage)
        // Shared stores; they load once and keep themselves current.
        async let favoritesTask: Void = channelFavorites?.loadIfNeeded() ?? ()
        async let myListTask: Void = myList?.reload() ?? ()

        let movieResult: Result<[Movie], any Error>
        do { movieResult = .success(try await moviesTask) } catch { movieResult = .failure(error) }
        let seriesResult: Result<[Series], any Error>
        do { seriesResult = .success(try await seriesTask) } catch { seriesResult = .failure(error) }
        let historyItems = await historyTask
        _ = await (favoritesTask, myListTask)

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
        case .success(let items):
            let unique = Self.uniqueByName(visible(items, .movies))
            movies = Array(unique.prefix(Self.popularCount))
            recentlyAddedMovies = HomeRows.recentlyAdded(unique) { $0.added }
        case .failure(let error): firstError = error
        }
        switch seriesResult {
        case .success(let items):
            let unique = Self.uniqueByName(visible(items, .series))
            series = Array(unique.prefix(Self.popularCount))
            recentlyAddedSeries = HomeRows.recentlyAdded(unique) { $0.lastModified }
        case .failure(let error): firstError = firstError ?? error
        }
        continueWatching = Self.continueWatching(from: historyItems ?? [], preferences: preferences)
        recentlyWatched = HomeRows.recentlyWatched(historyItems ?? [])

        if isEmpty, let firstError {
            errorMessage = (firstError as? APIError)?.userMessage ?? APIError.unknown.userMessage
        }
        isLoading = false
        hasLoaded = true
    }

    private static let catalogPage = 60
    private static let popularCount = 30

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
