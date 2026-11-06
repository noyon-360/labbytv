import Foundation
import os

nonisolated struct CatalogRepositoryLive: CatalogRepository {
    let client: APIClient
    /// Read on demand so switching playlists takes effect immediately.
    let credentials: @Sendable () async -> ServerCredentials?

    private func requireCredentials() async throws -> ServerCredentials {
        guard let credentials = await credentials() else { throw APIError.noPlaylist }
        return credentials
    }

    func categories(for type: ContentType) async throws -> [Category] {
        let credentials = try await requireCredentials()
        let body = CatalogRequest(credentials: credentials, type: type.categoryType)
        let list: LossyArray<Category> = try await client.post(.categories, body: body)
        return list.elements.filter { !$0.id.isEmpty }
    }

    func items<Item: CatalogItem>(
        _ type: ContentType,
        categoryID: String?,
        search: String?,
        page: Int,
        limit: Int
    ) async throws -> [Item] {
        let credentials = try await requireCredentials()
        let list: LossyArray<Item>
        if let categoryID, !categoryID.isEmpty {
            let body = CatalogRequest(credentials: credentials, type: type.categoryType, limit: limit, page: page)
            list = try await client.post(.categoryItems(categoryID), body: body)
        } else {
            let query = search?.trimmingCharacters(in: .whitespaces)
            let body = CatalogRequest(
                credentials: credentials,
                type: type.catalogType,
                search: (query?.isEmpty ?? true) ? nil : query,
                limit: limit,
                page: page
            )
            list = try await client.post(.connectTV, body: body)
        }
        return list.elements
    }

    func liveStreamURL(channelID: Int) async throws -> URL {
        let credentials = try await requireCredentials()
        let body = PlayURLRequest(credentials: credentials, type: .channels, streamId: channelID)
        let response: PlayURLResponse<EmptyResponse> = try await client.post(.playURL, body: body)
        return try Self.url(from: response.playUrl, type: .channels)
    }

    func movieDetail(id: Int) async throws -> (info: MovieInfo?, playURL: URL?) {
        let credentials = try await requireCredentials()
        let body = PlayURLRequest(credentials: credentials, type: .movies, streamId: id)
        let response: PlayURLResponse<MovieInfo> = try await client.post(.playURL, body: body)
        return (response.info, try? Self.url(from: response.playUrl, type: .movies))
    }

    func seriesDetail(id: Int) async throws -> SeriesInfo {
        let credentials = try await requireCredentials()
        let body = PlayURLRequest(credentials: credentials, type: .series, streamId: id)
        let response: PlayURLResponse<SeriesInfo> = try await client.post(.playURL, body: body)
        guard let info = response.info else { throw APIError.decoding }
        return info
    }

    func episodeURL(for episode: Episode) async throws -> URL {
        let credentials = try await requireCredentials()
        guard var components = URLComponents(string: credentials.serverUrl) else {
            throw APIError.server(status: 0, message: "The playlist server URL is invalid.")
        }
        let ext = episode.containerExtension.isEmpty ? "mkv" : episode.containerExtension
        components.percentEncodedPath = "/series/\(Self.pathSafe(credentials.username))/\(Self.pathSafe(credentials.password))/\(Self.pathSafe(episode.id)).\(ext)"
        components.query = nil
        guard let url = components.url else { throw APIError.decoding }
        Logger.player.info("Episode stream format: .\(ext, privacy: .public)")
        return url
    }

    private static func pathSafe(_ value: String) -> String {
        value.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed.subtracting(CharacterSet(charactersIn: "/"))) ?? value
    }

    /// The play URL embeds the IPTV username/password: only its extension is logged.
    private static func url(from string: String, type: ContentType) throws -> URL {
        guard let url = URL(string: string), url.scheme != nil else {
            throw APIError.server(status: 0, message: "This stream has no playable address.")
        }
        Logger.player.info("\(type.rawValue, privacy: .public) stream format: .\(url.pathExtension, privacy: .public)")
        return url
    }
}
