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
}
