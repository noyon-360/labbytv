import Foundation

/// `get_vod_info` payload inside `/server/get-play-url` for movies.
/// Mirrors Flutter `StreamData` (`info` + `movie_data`).
nonisolated struct MovieInfo: Decodable, Sendable {
    let name: String
    let originalName: String
    let coverBig: String
    let movieImage: String
    let releaseDate: String
    let director: String
    let cast: String
    let plot: String
    let genre: String
    let duration: String
    let durationSecs: Int
    let rating: Double
    let backdropPath: [String]
    let containerExtension: String

    var posterURL: URL? { URL(xtreamImage: movieImage) ?? URL(xtreamImage: coverBig) }
    var backdropURL: URL? { backdropPath.lazy.compactMap { URL(xtreamImage: $0) }.first ?? URL(xtreamImage: coverBig) }

    private enum CodingKeys: String, CodingKey {
        case info
        case movieData = "movie_data"
    }

    private enum InfoKeys: String, CodingKey {
        case name, director, actors, cast, description, plot, genre, duration, rating
        case originalName = "o_name"
        case coverBig = "cover_big"
        case movieImage = "movie_image"
        case releaseDate = "releasedate"
        case durationSecs = "duration_secs"
        case backdropPath = "backdrop_path"
    }

    private enum MovieDataKeys: String, CodingKey {
        case name
        case containerExtension = "container_extension"
    }

    init(from decoder: any Decoder) throws {
        let root = try decoder.container(keyedBy: CodingKeys.self)
        // PHP serialises an empty `info` as `[]`, so a failed nested container means "no info".
        let info = try? root.nestedContainer(keyedBy: InfoKeys.self, forKey: .info)
        let movieData = try? root.nestedContainer(keyedBy: MovieDataKeys.self, forKey: .movieData)

        name = info?.lenientString(.name).flatMap { $0.isEmpty ? nil : $0 }
            ?? movieData?.lenientString(.name) ?? ""
        originalName = info?.lenientString(.originalName) ?? ""
        coverBig = info?.lenientString(.coverBig) ?? ""
        movieImage = info?.lenientString(.movieImage) ?? ""
        releaseDate = info?.lenientString(.releaseDate) ?? ""
        director = info?.lenientString(.director) ?? ""
        let cast = info?.lenientString(.cast) ?? ""
        self.cast = cast.isEmpty ? (info?.lenientString(.actors) ?? "") : cast
        let plot = info?.lenientString(.plot) ?? ""
        self.plot = plot.isEmpty ? (info?.lenientString(.description) ?? "") : plot
        genre = info?.lenientString(.genre) ?? ""
        duration = info?.lenientString(.duration) ?? ""
        durationSecs = info?.lenientInt(.durationSecs) ?? 0
        rating = info?.lenientDouble(.rating) ?? 0
        backdropPath = info?.lenientStringArray(.backdropPath) ?? []
        containerExtension = movieData?.lenientString(.containerExtension) ?? ""
    }
}
