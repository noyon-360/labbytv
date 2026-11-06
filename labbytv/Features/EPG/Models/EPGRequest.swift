import Foundation

/// Body for `/epg/schedule`. With `from`/`to` (Unix seconds, UTC) the backend
/// returns every programme overlapping the window; without them, now + next.
nonisolated struct EPGRequest: Encodable, Sendable {
    let serverUrl: String
    let username: String
    let password: String
    let streamId: Int
    let from: Int?
    let to: Int?
    let limit: Int?

    init(credentials: ServerCredentials, streamId: Int, from: Date? = nil, to: Date? = nil, limit: Int? = nil) {
        serverUrl = credentials.serverUrl
        username = credentials.username
        password = credentials.password
        self.streamId = streamId
        self.from = from.map(DateFormatting.unixSeconds)
        self.to = to.map(DateFormatting.unixSeconds)
        self.limit = limit
    }
}
