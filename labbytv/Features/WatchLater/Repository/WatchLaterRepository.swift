import Foundation

/// "My List" on the active playlist, per viewer profile (backend `/watch-later`).
nonisolated protocol WatchLaterRepository: Sendable {
    func list(page: Int, limit: Int) async throws -> [WatchLaterItem]
    func status(videoType: String, videoID: String) async throws -> WatchLaterStatus
    func add(videoType: String, videoID: String, title: String, thumbnail: String?) async throws -> WatchLaterItem
    func remove(id: String) async throws
}
