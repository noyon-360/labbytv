import Foundation
import Observation

/// Add Profile (`profile == nil`) or edit an existing one.
@MainActor
@Observable
final class EditViewerProfileViewModel {
    var name: String
    var avatar: String
    private(set) var isSaving = false
    private(set) var error: String?

    let profile: ViewerProfile?
    @ObservationIgnored private let store: ViewerProfileStore

    /// The backend's limit (`assertName`).
    static let maxNameLength = 20

    init(profile: ViewerProfile?, store: ViewerProfileStore) {
        self.profile = profile
        self.store = store
        name = profile?.name ?? ""
        avatar = profile?.avatar ?? Self.firstUnusedAvatar(in: store.profiles)
    }

    var isNew: Bool { profile == nil }
    var title: String { isNew ? "Add Profile" : "Edit Profile" }
    var canDelete: Bool { profile.map { !$0.isDefault } ?? false }
    var isMainProfile: Bool { profile?.isDefault ?? false }

    var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }

    /// Returns true when saved, so the view can go back.
    func save() async -> Bool {
        guard !isSaving else { return false }
        let name = trimmedName
        guard !name.isEmpty, name.count <= Self.maxNameLength else {
            error = "Name must be 1–\(Self.maxNameLength) characters."
            return false
        }
        isSaving = true
        defer { isSaving = false }
        error = nil
        if let profile {
            // Only send what changed.
            error = await store.update(
                profile,
                name: name == profile.name ? nil : name,
                avatar: avatar == profile.avatar ? nil : avatar
            )
        } else {
            error = await store.create(name: name, avatar: avatar)
        }
        return error == nil
    }

    func delete() async -> Bool {
        guard let profile, canDelete, !isSaving else { return false }
        isSaving = true
        defer { isSaving = false }
        error = await store.delete(profile)
        return error == nil
    }

    /// A new profile starts on an avatar nobody uses yet, so tiles differ.
    static func firstUnusedAvatar(in profiles: [ViewerProfile]) -> String {
        let used = Set(profiles.map(\.avatar))
        return AvatarPreset.all.first { !used.contains($0.key) }?.key ?? AvatarPreset.defaultKey
    }
}
