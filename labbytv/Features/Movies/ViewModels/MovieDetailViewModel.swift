import Foundation
import Observation

@MainActor
@Observable
final class MovieDetailViewModel {
    let movie: Movie
    private(set) var info: MovieInfo?
    private(set) var isLoading = false
    private(set) var errorMessage: String?
    private(set) var isFavorite = false
    private(set) var resumePosition: Double?

    @ObservationIgnored private let catalog: any CatalogRepository
    @ObservationIgnored private let history: any WatchHistoryRepository
    @ObservationIgnored private var isTogglingFavorite = false

    init(movie: Movie, catalog: any CatalogRepository, history: any WatchHistoryRepository) {
        self.movie = movie
        self.catalog = catalog
        self.history = history
    }

    var title: String { info?.name.isEmpty == false ? info!.name : movie.name }
    var posterURL: URL? { info?.posterURL ?? movie.imageURL }
    var thumbnail: String { info?.movieImage.isEmpty == false ? info!.movieImage : movie.streamIcon }

    var metadataLine: String {
        guard let info else { return "" }
        let year = String(info.releaseDate.prefix(4))
        let duration = info.durationSecs > 0 ? DateFormatting.duration(seconds: info.durationSecs) : info.duration
        let rating = info.rating > 0 ? "★ \(String(format: "%.1f", info.rating))" : ""
        return [year, duration, info.genre, rating].filter { !$0.isEmpty }.joined(separator: "  ·  ")
    }

    var playableItem: PlayableItem {
        .movie(id: movie.id, title: title, thumbnail: thumbnail)
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        async let detail = catalog.movieDetail(id: movie.id)
        async let status = try? history.status(videoID: String(movie.id))
        do {
            info = try await detail.info
        } catch is CancellationError {
            return
        } catch {
            errorMessage = (error as? APIError)?.userMessage ?? APIError.unknown.userMessage
        }
        if let status = await status {
            isFavorite = status.isLoved
            resumePosition = status.resumePosition
        }
    }

    /// Re-read resume position after the player closes.
    func refreshStatus() async {
        guard let status = try? await history.status(videoID: String(movie.id)) else { return }
        isFavorite = status.isLoved
        resumePosition = status.resumePosition
    }

    /// Optimistic, rolled back on failure (same as Flutter `toggleFavorite`).
    func toggleFavorite() async {
        guard !isTogglingFavorite else { return }
        isTogglingFavorite = true
        defer { isTogglingFavorite = false }
        let newValue = !isFavorite
        isFavorite = newValue
        var request = UpdateVideoStatusRequest(title: title, videoId: String(movie.id), videoType: "movie")
        request.isLoved = newValue
        request.thumbnail = thumbnail.isEmpty ? nil : thumbnail
        do {
            try await history.update(request)
        } catch {
            isFavorite = !newValue
        }
    }
}
