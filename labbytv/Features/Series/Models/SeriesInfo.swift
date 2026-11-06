import Foundation

/// `get_series_info` payload inside `/server/get-play-url` for series.
/// Mirrors Flutter `SeriesDataContent`.
nonisolated struct SeriesInfo: Decodable, Sendable {
    let name: String
    let cover: String
    let plot: String
    let cast: String
    let director: String
    let genre: String
    let releaseDate: String
    let backdropPath: [String]
    let seasons: [Season]
    /// Keyed by season number.
    let episodes: [Int: [Episode]]

    var coverURL: URL? { URL(xtreamImage: cover) }
    var backdropURL: URL? { backdropPath.lazy.compactMap { URL(xtreamImage: $0) }.first ?? coverURL }

    /// Seasons that actually have episodes. Some providers list seasons with
    /// no episodes, or episodes for seasons missing from `seasons`.
    var playableSeasons: [Season] {
        let known = Dictionary(seasons.map { ($0.seasonNumber, $0) }, uniquingKeysWith: { first, _ in first })
        return episodes.keys.sorted().map { number in
            known[number] ?? Season(seasonNumber: number, name: "Season \(number)")
        }
    }

    private enum CodingKeys: String, CodingKey {
        case info, seasons, episodes
    }

    private enum InfoKeys: String, CodingKey {
        case name, cover, plot, cast, director, genre, releaseDate
        case releaseDateSnake = "release_date"
        case backdropPath = "backdrop_path"
    }

    init(from decoder: any Decoder) throws {
        let root = try decoder.container(keyedBy: CodingKeys.self)
        let info = try? root.nestedContainer(keyedBy: InfoKeys.self, forKey: .info)
        name = info?.lenientString(.name) ?? ""
        cover = info?.lenientString(.cover) ?? ""
        plot = info?.lenientString(.plot) ?? ""
        cast = info?.lenientString(.cast) ?? ""
        director = info?.lenientString(.director) ?? ""
        genre = info?.lenientString(.genre) ?? ""
        releaseDate = info?.lenientString(.releaseDate) ?? info?.lenientString(.releaseDateSnake) ?? ""
        backdropPath = info?.lenientStringArray(.backdropPath) ?? []

        // PHP sends an empty collection as `{}` and a full one as either an
        // array or an object keyed by index, so accept both shapes.
        if let list = try? root.decode(LossyArray<Season>.self, forKey: .seasons) {
            seasons = list.elements
        } else if let map = try? root.decode([String: Season].self, forKey: .seasons) {
            seasons = Array(map.values)
        } else {
            seasons = []
        }

        var episodes: [Int: [Episode]] = [:]
        if let map = try? root.decode([String: LossyArray<Episode>].self, forKey: .episodes) {
            for (key, value) in map {
                guard let number = Int(key) else { continue }
                episodes[number] = value.elements.sorted { $0.episodeNum < $1.episodeNum }
            }
        }
        self.episodes = episodes
    }
}
