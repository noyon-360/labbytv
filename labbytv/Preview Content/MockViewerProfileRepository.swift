#if DEBUG
import Foundation

/// In-memory profiles, so previews and the `-UITestMockData` run can add,
/// edit and delete without a backend.
actor MockViewerProfileRepository: ViewerProfileRepository {
    private var profiles: [ViewerProfile]
    private let maxProfiles = 5

    init(profiles: [ViewerProfile] = MockData.viewerProfiles) {
        self.profiles = profiles
    }

    func list() async throws -> ViewerProfileList {
        ViewerProfileList(profiles: profiles, maxProfiles: maxProfiles)
    }

    func create(name: String, avatar: String) async throws -> ViewerProfile {
        guard profiles.count < maxProfiles else {
            throw APIError.server(status: 400, message: "An account can have up to \(maxProfiles) profiles.")
        }
        try checkName(name, except: nil)
        let profile = ViewerProfile(id: UUID().uuidString, name: name, avatar: avatar)
        profiles.append(profile)
        return profile
    }

    func update(id: String, name: String?, avatar: String?) async throws -> ViewerProfile {
        guard let index = profiles.firstIndex(where: { $0.id == id }) else {
            throw APIError.server(status: 404, message: "Profile not found.")
        }
        if let name { try checkName(name, except: id) }
        let old = profiles[index]
        let updated = ViewerProfile(id: id, name: name ?? old.name, avatar: avatar ?? old.avatar, isDefault: old.isDefault)
        profiles[index] = updated
        return updated
    }

    func delete(id: String) async throws {
        if profiles.first(where: { $0.id == id })?.isDefault == true {
            throw APIError.server(status: 400, message: "The main profile can't be deleted.")
        }
        profiles.removeAll { $0.id == id }
    }

    private func checkName(_ name: String, except id: String?) throws {
        if profiles.contains(where: { $0.id != id && $0.name.lowercased() == name.lowercased() }) {
            throw APIError.server(status: 409, message: "Another profile already has this name.")
        }
    }
}
#endif
