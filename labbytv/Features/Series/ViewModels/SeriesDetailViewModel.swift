import Foundation
import Observation

@MainActor
@Observable
final class SeriesDetailViewModel {
    let series: Series
    private(set) var info: SeriesInfo?
    private(set) var selectedSeason: Int?
    private(set) var isLoading = false
    private(set) var errorMessage: String?
    private(set) var isFavorite = false

    @ObservationIgnored private let catalog: any CatalogRepository
    @ObservationIgnored private let history: any WatchHistoryRepository
    @ObservationIgnored private var isTogglingFavorite = false

    init(series: Series, catalog: any CatalogRepository, history: any WatchHistoryRepository) {
        self.series = series
        self.catalog = catalog
        self.history = history
    }

    var title: String { info?.name.isEmpty == false ? info!.name : series.name }
    var cover: String { info?.cover.isEmpty == false ? info!.cover : series.cover }
    var seasons: [Season] { info?.playableSeasons ?? [] }
    var episodes: [Episode] {
        guard let selectedSeason else { return [] }
        return info?.episodes[selectedSeason] ?? []
    }

    var context: EpisodeContext {
        EpisodeContext(seriesID: series.id, seriesTitle: title, cover: cover)
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        // Series favourites are stored at the show level, keyed by series id.
        async let status = try? history.status(videoID: String(series.id))
        do {
            let loaded = try await catalog.seriesDetail(id: series.id)
            info = loaded
            if selectedSeason == nil {
                selectedSeason = loaded.playableSeasons.first?.seasonNumber
            }
        } catch is CancellationError {
            return
        } catch {
            errorMessage = (error as? APIError)?.userMessage ?? APIError.unknown.userMessage
        }
        if let status = await status {
            isFavorite = status.isLoved
        }
    }

    func selectSeason(_ number: Int) {
        selectedSeason = number
    }

    func toggleFavorite() async {
        guard !isTogglingFavorite else { return }
        isTogglingFavorite = true
        defer { isTogglingFavorite = false }
        let newValue = !isFavorite
        isFavorite = newValue
        var request = UpdateVideoStatusRequest(title: title, videoId: String(series.id), videoType: "series")
        request.isLoved = newValue
        request.thumbnail = cover.isEmpty ? nil : cover
        do {
            try await history.update(request)
        } catch {
            isFavorite = !newValue
        }
    }
}
