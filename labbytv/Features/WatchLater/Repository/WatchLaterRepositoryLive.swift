import Foundation

nonisolated struct WatchLaterRepositoryLive: WatchLaterRepository {
    let client: APIClient
    /// The active playlist's backend id; My List is kept per playlist.
    let playlistID: @Sendable () async -> String?

    func list(page: Int, limit: Int) async throws -> [WatchLaterItem] {
        let playlist = try await requirePlaylist()
        let result: WatchLaterPage = try await client.get(.watchLater, query: [
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "playlistId", value: playlist),
        ])
        return result.items
    }

    func status(videoType: String, videoID: String) async throws -> WatchLaterStatus {
        let playlist = try await requirePlaylist()
        return try await client.get(.watchLaterStatus, query: [
            URLQueryItem(name: "playlistId", value: playlist),
            URLQueryItem(name: "videoType", value: videoType),
            URLQueryItem(name: "videoId", value: videoID),
        ])
    }

    func add(videoType: String, videoID: String, title: String, thumbnail: String?) async throws -> WatchLaterItem {
        let playlist = try await requirePlaylist()
        let body = AddWatchLaterRequest(playlistId: playlist, videoType: videoType, videoId: videoID, title: title, thumbnail: thumbnail)
        return try await client.post(.watchLater, body: body)
    }

    func remove(id: String) async throws {
        let _: EmptyResponse = try await client.delete(.watchLaterItem(id))
    }

    private func requirePlaylist() async throws -> String {
        guard let id = await playlistID(), !id.isEmpty else { throw APIError.noPlaylist }
        return id
    }
}
