import Foundation

/// Body for `/server/connect-tv`, `/category` and `/category/{id}`.
/// Mirrors Flutter `ServerRequestModel.toJson()`.
nonisolated struct CatalogRequest: Encodable, Sendable {
    let serverUrl: String
    let username: String
    let password: String
    let type: String
    let search: String?
    let limit: Int
    let page: Int

    init(credentials: ServerCredentials, type: String, search: String? = nil, limit: Int = 50, page: Int = 1) {
        serverUrl = credentials.serverUrl
        username = credentials.username
        password = credentials.password
        self.type = type
        self.search = search
        self.limit = limit
        self.page = page
    }
}
