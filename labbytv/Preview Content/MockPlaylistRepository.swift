#if DEBUG
import Foundation

nonisolated struct MockPlaylistRepository: PlaylistRepository {
    var items: [Playlist] = MockData.playlists

    func playlists() async throws -> [Playlist] { items }
    func add(_ request: AddPlaylistRequest) async throws {}
}
#endif
