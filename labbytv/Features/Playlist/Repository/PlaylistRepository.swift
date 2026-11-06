import Foundation

nonisolated protocol PlaylistRepository: Sendable {
    func playlists() async throws -> [Playlist]
    func add(_ request: AddPlaylistRequest) async throws
}
