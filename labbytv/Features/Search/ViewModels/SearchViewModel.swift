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
    private static let limit = 20

    init(catalog: any CatalogRepository) {
        self.catalog = catalog
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
        channels = foundChannels
        movies = foundMovies
        series = foundSeries
        lastSearched = text
        if !hasResults, let failure, !(failure is CancellationError) {
            errorMessage = (failure as? APIError)?.userMessage ?? APIError.unknown.userMessage
        }
    }
}
