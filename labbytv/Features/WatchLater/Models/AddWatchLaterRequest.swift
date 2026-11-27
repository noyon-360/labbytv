import Foundation

/// Body of `POST /watch-later` (same fields as Flutter `WatchLaterRepoImpl.add`).
nonisolated struct AddWatchLaterRequest: Encodable, Sendable {
    let playlistId: String
    let videoType: String
    let videoId: String
    let title: String
    let thumbnail: String?
}
