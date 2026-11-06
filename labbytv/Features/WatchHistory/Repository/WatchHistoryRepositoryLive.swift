import Foundation

nonisolated struct WatchHistoryRepositoryLive: WatchHistoryRepository {
    let client: APIClient

    func history(page: Int, limit: Int) async throws -> [WatchHistoryItem] {
        let result: WatchHistoryPage = try await client.get(.watchHistory, query: Self.paging(page, limit))
        return result.items
    }

    func favorites(page: Int, limit: Int) async throws -> [WatchHistoryItem] {
        let result: WatchHistoryPage = try await client.get(.favorites, query: Self.paging(page, limit))
        return result.items
    }

    func status(videoID: String) async throws -> VideoStatus {
        try await client.get(.videoStatus(videoID))
    }

    func update(_ request: UpdateVideoStatusRequest) async throws {
        let _: EmptyResponse = try await client.post(.updateVideoStatus, body: request)
    }

    private static func paging(_ page: Int, _ limit: Int) -> [URLQueryItem] {
        [URLQueryItem(name: "page", value: String(page)), URLQueryItem(name: "limit", value: String(limit))]
    }
}
