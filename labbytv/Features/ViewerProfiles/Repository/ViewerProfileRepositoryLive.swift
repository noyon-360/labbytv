import Foundation

nonisolated struct ViewerProfileRepositoryLive: ViewerProfileRepository {
    let client: APIClient

    func list() async throws -> ViewerProfileList {
        try await client.get(.viewerProfiles)
    }

    func create(name: String, avatar: String) async throws -> ViewerProfile {
        try await client.post(.viewerProfiles, body: ViewerProfileRequest(name: name, avatar: avatar))
    }

    func update(id: String, name: String?, avatar: String?) async throws -> ViewerProfile {
        try await client.patch(.viewerProfile(id), body: ViewerProfileRequest(name: name, avatar: avatar))
    }

    func delete(id: String) async throws {
        let _: EmptyResponse = try await client.delete(.viewerProfile(id))
    }
}
