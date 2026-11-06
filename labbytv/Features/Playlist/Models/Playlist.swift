import Foundation

/// One of the user's IPTV provider accounts. Mirrors Flutter `PlaylistModel`.
nonisolated struct Playlist: Codable, Sendable, Hashable, Identifiable {
    let id: String
    let name: String
    let url: String
    let userName: String
    let password: String

    var credentials: ServerCredentials {
        ServerCredentials(serverUrl: url, username: userName, password: password)
    }

    init(id: String, name: String, url: String, userName: String, password: String) {
        self.id = id
        self.name = name
        self.url = url
        self.userName = userName
        self.password = password
    }

    private enum CodingKeys: String, CodingKey {
        case id = "_id"
        case name, url, userName, password
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = container.lenientString(.id) ?? ""
        name = container.lenientString(.name) ?? ""
        url = container.lenientString(.url) ?? ""
        userName = container.lenientString(.userName) ?? ""
        password = container.lenientString(.password) ?? ""
    }
}
