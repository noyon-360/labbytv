import Foundation

nonisolated struct PlaylistRepositoryLive: PlaylistRepository {
    let client: APIClient

    func playlists() async throws -> [Playlist] {
        let list: LossyArray<Playlist> = try await client.get(.getPlaylists)
        return list.elements
    }

    func add(_ request: AddPlaylistRequest) async throws {
        let _: EmptyResponse = try await client.post(.addPlaylist, body: request)
    }
}
