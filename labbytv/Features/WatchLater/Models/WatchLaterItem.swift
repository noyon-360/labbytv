import Foundation

/// A title on "My List" (backend `/watch-later`). Mirrors Flutter
/// `WatchLaterItem`. Items belong to one playlist, because Xtream ids only
/// mean something on the provider they came from.
nonisolated struct WatchLaterItem: Decodable, Sendable, Hashable, Identifiable {
    let id: String
    /// `movie` or `series`.
    let videoType: String
    let videoId: String
    let title: String
    let thumbnail: String

    var imageURL: URL? { URL(xtreamImage: thumbnail) }
    var isSeries: Bool { videoType == "series" }

    /// Where selecting it goes: the movie or series detail page.
    var route: AppRoute? {
        guard let id = Int(videoId) else { return nil }
        return isSeries
            ? .series(Series(id: id, name: title, cover: thumbnail))
            : .movie(Movie(id: id, name: title, streamIcon: thumbnail))
    }

    init(id: String, videoType: String, videoId: String, title: String, thumbnail: String = "") {
        self.id = id
        self.videoType = videoType
        self.videoId = videoId
        self.title = title
        self.thumbnail = thumbnail
    }

    private enum CodingKeys: String, CodingKey {
        case id = "_id"
        case videoType, videoId, title, thumbnail
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = container.lenientString(.id) ?? ""
        videoType = (container.lenientString(.videoType) ?? "movie").lowercased()
        videoId = container.lenientString(.videoId) ?? ""
        title = container.lenientString(.title) ?? ""
        thumbnail = container.lenientString(.thumbnail) ?? ""
    }
}
