import Foundation

/// Catalog, categories and play URLs for live, movies and series.
/// The Flutter app splits this across LiveTvRepo / MovieRepo / SeriesRepo /
/// GenreRepo / SearchRepo, but they all hit the same three endpoints with
/// the same body, so one repository covers them.
nonisolated protocol CatalogRepository: Sendable {
    func categories(for type: ContentType) async throws -> [Category]

    /// One page of the catalog. `categoryID == nil` loads everything;
    /// `search` filters by name on the backend.
    func items<Item: CatalogItem>(
        _ type: ContentType,
        categoryID: String?,
        search: String?,
        page: Int,
        limit: Int
    ) async throws -> [Item]

    func liveStreamURL(channelID: Int) async throws -> URL
    func movieDetail(id: Int) async throws -> (info: MovieInfo?, playURL: URL?)
    func seriesDetail(id: Int) async throws -> SeriesInfo
    /// Episodes are played straight from the provider, built like the Flutter
    /// app does (`/series/{user}/{pass}/{id}.{ext}` on the playlist host).
    func episodeURL(for episode: Episode) async throws -> URL
}
