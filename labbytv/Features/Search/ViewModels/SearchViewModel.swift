import Foundation
import Observation

/// Searches channels, movies and series in parallel (backend name filter).
@MainActor
@Observable
final class SearchViewModel {
    var query = ""
    private(set) var channels: [Channel] = []
    private(set) var movies: [Movie] = []
    private(set) var series: [Series] = []
    private(set) var isSearching = false
    private(set) var errorMessage: String?
    private(set) var lastSearched = ""

    @ObservationIgnored private let catalog: any CatalogRepository
    @ObservationIgnored private let parentalLock: ParentalLockService?
    @ObservationIgnored private var seenLockChange = 0
    @ObservationIgnored private var seenLockReveal = 0
    private static let limit = 20

    init(catalog: any CatalogRepository, parentalLock: ParentalLockService? = nil) {
        self.catalog = catalog
        self.parentalLock = parentalLock
        seenLockChange = parentalLock?.changeCount ?? 0
        seenLockReveal = parentalLock?.revealCount ?? 0
    }

    /// Observed by the view so results follow lock changes right away.
    var parentalLockChangeCount: Int { parentalLock?.changeCount ?? 0 }

    /// Drops newly locked results, or searches again when something was revealed.
    func applyParentalLockChanges() async {
        guard let parentalLock, parentalLock.changeCount != seenLockChange else { return }
        let reveals = parentalLock.revealCount != seenLockReveal
        seenLockChange = parentalLock.changeCount
        seenLockReveal = parentalLock.revealCount
        if reveals && !lastSearched.isEmpty {
            await search()
        } else {
            channels = visible(channels, .channels)
            movies = visible(movies, .movies)
            series = visible(series, .series)
        }
    }

    private func visible<Item: CatalogItem>(_ items: [Item], _ type: ContentType) -> [Item] {
        guard let parentalLock else { return items }
        return items.filter { !parentalLock.isHidden(type, categoryID: $0.categoryId) }
    }

    var hasResults: Bool { !channels.isEmpty || !movies.isEmpty || !series.isEmpty }

    /// Call from `.task(id: query)`: the sleep debounces typing, and the
    /// task is cancelled when the query changes again.
    func search() async {
        let text = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard text.count >= 2 else {
            channels = []; movies = []; series = []
            lastSearched = ""
            errorMessage = nil
            return
        }
        do {
            try await Task.sleep(for: .milliseconds(450))
        } catch {
            return
        }

        isSearching = true
        errorMessage = nil
        defer { isSearching = false }

        async let channelsTask: [Channel] = catalog.items(.channels, categoryID: nil, search: text, page: 1, limit: Self.limit)
        async let moviesTask: [Movie] = catalog.items(.movies, categoryID: nil, search: text, page: 1, limit: Self.limit)
        async let seriesTask: [Series] = catalog.items(.series, categoryID: nil, search: text, page: 1, limit: Self.limit)

        var failure: Error?
        let foundChannels: [Channel]
        let foundMovies: [Movie]
        let foundSeries: [Series]
        do { foundChannels = try await channelsTask } catch { foundChannels = []; failure = error }
        do { foundMovies = try await moviesTask } catch { foundMovies = []; failure = failure ?? error }
        do { foundSeries = try await seriesTask } catch { foundSeries = []; failure = failure ?? error }

        guard !Task.isCancelled else { return }
        channels = visible(foundChannels, .channels)
        movies = visible(foundMovies, .movies)
        series = visible(foundSeries, .series)
        lastSearched = text
        if !hasResults, let failure, !(failure is CancellationError) {
            errorMessage = (failure as? APIError)?.userMessage ?? APIError.unknown.userMessage
        }
    }
}
