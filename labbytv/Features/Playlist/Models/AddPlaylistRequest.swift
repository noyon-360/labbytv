import Foundation

/// Body for `/playlist/add-playlist`. Mirrors Flutter `PlaylistModel.toJson()`.
nonisolated struct AddPlaylistRequest: Encodable, Sendable {
    let name: String
    let userName: String
    let password: String
    let url: String
}
