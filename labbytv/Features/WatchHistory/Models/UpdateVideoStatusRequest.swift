import Foundation

/// Body for `/watch-history/update`. Mirrors Flutter `UpdateVideoStatusRequest`;
/// `nil` fields are left out so the backend doesn't overwrite them.
nonisolated struct UpdateVideoStatusRequest: Encodable, Sendable {
    let title: String
    let videoId: String
    /// `movie`, `series` or `live`.
    let videoType: String
    var currentTime: Double?
    var duration: Double?
    var seasonNumber: Int?
    var episodeNumber: Int?
    var isLoved: Bool?
    var thumbnail: String?
    /// The title's / channel's category, for category badges on favourites
    /// and history. Left out when unknown, so the backend keeps what it has.
    var categoryId: String?
    var categoryName: String?
}

nonisolated extension UpdateVideoStatusRequest {
    /// Empty Xtream values become `nil` (not sent).
    mutating func setCategory(id: String, name: String?) {
        categoryId = id.isEmpty ? nil : id
        categoryName = (name?.isEmpty ?? true) ? nil : name
    }
}
