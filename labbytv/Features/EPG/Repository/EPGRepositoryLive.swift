import Foundation

nonisolated struct EPGRepositoryLive: EPGRepository {
    let client: APIClient
    let credentials: @Sendable () async -> ServerCredentials?

    func schedule(channelID: Int, from: Date, to: Date) async throws -> [EPGProgram] {
        guard let credentials = await credentials() else { throw APIError.noPlaylist }
        let body = EPGRequest(credentials: credentials, streamId: channelID, from: from, to: to)
        let list: LossyArray<EPGProgram> = try await client.post(.epgSchedule, body: body)
        return list.elements.sorted { $0.start < $1.start }
    }
}
