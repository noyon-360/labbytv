import Foundation
import Observation
import os

/// Who is signed in and which playlist is active.
/// `AppRouter` switches between Login, Playlist picker and the main tabs on these.
@MainActor
@Observable
final class SessionStore {
    private(set) var isLoggedIn: Bool
    private(set) var userId: String?
    private(set) var activePlaylist: Playlist?
    /// Filled by the login response or `/user/profile`.
    private(set) var currentUser: User?

    @ObservationIgnored private let store: any SecureStore

    init(store: any SecureStore) {
        self.store = store
        self.isLoggedIn = store.string(for: .accessToken) != nil
        self.userId = store.string(for: .userId)
        self.activePlaylist = store.string(for: .activePlaylist)
            .flatMap { try? JSONDecoder().decode(Playlist.self, from: Data($0.utf8)) }
    }

    var credentials: ServerCredentials? { activePlaylist?.credentials }

    /// Saves the tokens from a successful login. Throws if the backend
    /// left either token out, so we never show a half-signed-in app.
    func signIn(with response: LoginResponse) throws {
        guard let accessToken = response.accessToken, !accessToken.isEmpty,
              let refreshToken = response.refreshToken, !refreshToken.isEmpty else {
            Logger.auth.error("Login response is missing a token")
            throw APIError.decoding
        }
        store.set(accessToken, for: .accessToken)
        store.set(refreshToken, for: .refreshToken)
        let id = response.user?.id ?? response.id
        if let id {
            store.set(id, for: .userId)
        }
        if let role = response.role {
            store.set(role, for: .role)
        }
        userId = id
        currentUser = response.user
        isLoggedIn = true
    }

    func updateUser(_ user: User) {
        currentUser = user
    }

    func selectPlaylist(_ playlist: Playlist) {
        if let data = try? JSONEncoder().encode(playlist) {
            store.set(String(decoding: data, as: UTF8.self), for: .activePlaylist)
        }
        activePlaylist = playlist
    }

    /// Back to the playlist picker without signing out.
    func clearPlaylist() {
        store.remove(.activePlaylist)
        activePlaylist = nil
    }

    /// Also called by `APIClient` when the refresh token is rejected.
    /// Safe to call more than once (several requests can 401 together).
    func signOut() {
        store.clearSession()
        currentUser = nil
        userId = nil
        activePlaylist = nil
        isLoggedIn = false
    }
}
