#if DEBUG
import Foundation

nonisolated struct MockCatalogRepository: CatalogRepository {
    var failure: APIError?

    func categories(for type: ContentType) async throws -> [Category] {
        MockData.categories
    }

    func items<Item: CatalogItem>(_ type: ContentType, categoryID: String?, search: String?, page: Int, limit: Int) async throws -> [Item] {
        try await Task.sleep(for: .milliseconds(300))
        if let failure { throw failure }
        guard page == 1 else { return [] }
        let all: [any CatalogItem] = switch type {
        case .channels: MockData.channels
        case .movies: MockData.movies
        case .series: MockData.series
        }
        let filtered = all.compactMap { $0 as? Item }.filter { item in
            guard let search, !search.isEmpty else { return true }
            return item.title.localizedCaseInsensitiveContains(search)
        }
        return Array(filtered.prefix(limit))
    }

    func liveStreamURL(channelID: Int) async throws -> URL {
        URL(string: "https://devstreaming-cdn.apple.com/videos/streaming/examples/img_bipbop_adv_example_fmp4/master.m3u8")!
    }

    func movieDetail(id: Int) async throws -> (info: MovieInfo?, playURL: URL?) {
        (MockData.movieInfo, URL(string: "https://devstreaming-cdn.apple.com/videos/streaming/examples/img_bipbop_adv_example_fmp4/master.m3u8"))
    }

    func seriesDetail(id: Int) async throws -> SeriesInfo {
        MockData.seriesInfo
    }

    func episodeURL(for episode: Episode) async throws -> URL {
        URL(string: "https://devstreaming-cdn.apple.com/videos/streaming/examples/img_bipbop_adv_example_fmp4/master.m3u8")!
    }
}
#endif
