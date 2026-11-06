import Foundation

/// Mirrors Flutter `Episode` + `EpisodeInfo` (`get_series_info.episodes[season][]`).
nonisolated struct Episode: Decodable, Sendable, Hashable, Identifiable {
    /// Xtream episode stream id, used in the play URL and as the watch-history `videoId`.
    let id: String
    let episodeNum: Int
    let title: String
    let season: Int
    let containerExtension: String
    let movieImage: String
    let durationSecs: Int
    let duration: String

    var imageURL: URL? { URL(xtreamImage: movieImage) }

    init(id: String, episodeNum: Int, title: String, season: Int, containerExtension: String = "", movieImage: String = "", durationSecs: Int = 0, duration: String = "") {
        self.id = id
        self.episodeNum = episodeNum
        self.title = title
        self.season = season
        self.containerExtension = containerExtension
        self.movieImage = movieImage
        self.durationSecs = durationSecs
        self.duration = duration
    }

    private enum CodingKeys: String, CodingKey {
        case id, title, season, info
        case episodeNum = "episode_num"
        case containerExtension = "container_extension"
    }

    private enum InfoKeys: String, CodingKey {
        case duration
        case movieImage = "movie_image"
        case durationSecs = "duration_secs"
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = container.lenientString(.id) ?? ""
        episodeNum = container.lenientInt(.episodeNum) ?? 0
        title = container.lenientString(.title) ?? ""
        season = container.lenientInt(.season) ?? 0
        containerExtension = container.lenientString(.containerExtension) ?? ""
        let info = try? container.nestedContainer(keyedBy: InfoKeys.self, forKey: .info)
        movieImage = info?.lenientString(.movieImage) ?? ""
        durationSecs = info?.lenientInt(.durationSecs) ?? 0
        duration = info?.lenientString(.duration) ?? ""
    }
}
