import Foundation

/// `data` of `GET /watch-later/status`: whether a title is on My List.
nonisolated struct WatchLaterStatus: Decodable, Sendable {
    let isSaved: Bool
    /// Needed to remove it (`DELETE /watch-later/:id`).
    let id: String?

    init(isSaved: Bool, id: String?) {
        self.isSaved = isSaved
        self.id = id
    }

    private enum CodingKeys: String, CodingKey {
        case isSaved, id
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        isSaved = container.lenientBool(.isSaved) ?? false
        let id = container.lenientString(.id)
        self.id = id?.isEmpty == false ? id : nil
    }
}
