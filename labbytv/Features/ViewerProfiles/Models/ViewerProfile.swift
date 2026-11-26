import Foundation

/// A viewer profile ("Who's Watching") inside the account. Not the account's
/// own details (`/user/profile`). Mirrors the backend `Profile` model and
/// Flutter `ViewerProfile`.
nonisolated struct ViewerProfile: Decodable, Sendable, Hashable, Identifiable {
    let id: String
    let name: String
    /// Preset key, `avatar_01`…`avatar_12` (see `AvatarPreset`).
    let avatar: String
    /// The account's main profile: always there, can't be deleted, and used
    /// by requests that don't name a profile.
    let isDefault: Bool
    let preferences: ViewerProfilePreferences

    init(id: String, name: String, avatar: String = AvatarPreset.defaultKey, isDefault: Bool = false, preferences: ViewerProfilePreferences = ViewerProfilePreferences()) {
        self.id = id
        self.name = name
        self.avatar = avatar
        self.isDefault = isDefault
        self.preferences = preferences
    }

    private enum CodingKeys: String, CodingKey {
        case mongoID = "_id"
        case id, name, avatar, isDefault, preferences
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = container.lenientString(.mongoID) ?? container.lenientString(.id) ?? ""
        name = container.lenientString(.name) ?? ""
        avatar = container.lenientString(.avatar) ?? AvatarPreset.defaultKey
        isDefault = (try? container.decodeIfPresent(Bool.self, forKey: .isDefault)) ?? false
        preferences = (try? container.decodeIfPresent(ViewerProfilePreferences.self, forKey: .preferences)) ?? ViewerProfilePreferences()
    }
}
