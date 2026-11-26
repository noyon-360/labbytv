import Foundation

/// `/profiles` on the backend. Mirrors Flutter `ViewerProfileRepo`.
nonisolated protocol ViewerProfileRepository: Sendable {
    func list() async throws -> ViewerProfileList
    func create(name: String, avatar: String) async throws -> ViewerProfile
    /// `nil` leaves a field unchanged.
    func update(id: String, name: String?, avatar: String?) async throws -> ViewerProfile
    /// Also deletes everything the profile saved. The main profile can't be deleted.
    func delete(id: String) async throws
}
