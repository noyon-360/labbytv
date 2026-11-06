import Foundation

/// Body for `/server/get-play-url`. Mirrors Flutter `SingleStreamRequestModel`.
nonisolated struct PlayURLRequest: Encodable, Sendable {
    let serverUrl: String
    let username: String
    let password: String
    let streamType: String
    let streamId: Int

    init(credentials: ServerCredentials, type: ContentType, streamId: Int) {
        serverUrl = credentials.serverUrl
        username = credentials.username
        password = credentials.password
        streamType = type.streamType
        self.streamId = streamId
    }

    private enum CodingKeys: String, CodingKey {
        case serverUrl, username, password
        case streamType = "stream_type"
        case streamId = "stream_id"
    }
}
