import Foundation
import Observation
import os

/// The viewer profile ("Who's Watching") this device uses.
///
/// `APIClient` sends the stored id as `X-Profile-ID` on every request, so
/// history, favourites and reminders are per profile. The choice is kept in
/// the Keychain with the session, so sign-out clears it. Mirrors Flutter
/// `ViewerProfileService`.
@MainActor
@Observable
final class ViewerProfileStore {
    enum Phase: Equatable {
        /// Loading the list to decide whether to ask.
        case deciding
        case picker
        case ready
    }

    private(set) var phase: Phase = .deciding
    private(set) var profiles: [ViewerProfile] = []
    private(set) var current: ViewerProfile?
    private(set) var maxProfiles = 5

    /// The first decision after launch always asks when there are several
    /// profiles (a shared TV); later ones (after sign-in) only when needed.
    @ObservationIgnored private var isFirstStart = true
    @ObservationIgnored private let repository: any ViewerProfileRepository
    @ObservationIgnored private let store: any SecureStore

    init(repository: any ViewerProfileRepository, store: any SecureStore) {
        self.repository = repository
        self.store = store
    }

    var canAddProfile: Bool { profiles.count < maxProfiles }

    /// The profile to highlight in "Who's Watching".
    var highlightedID: String? { current?.id ?? storedID }

    /// "Who's Watching" was opened from the app (Switch Profile), so Back
    /// returns to it rather than leaving the app.
    var canCancelPicker: Bool { current != nil }

    private var storedID: String? { store.string(for: .viewerProfileId) }

    /// Decides between "Who's Watching" and the app. Offline or a server
    /// error: carry on with the profile used last time (the header still
    /// names it), so a flaky network never blocks the app.
    func start() async {
        let askWhenSeveral = isFirstStart
        isFirstStart = false
        guard await load() else {
            phase = .ready
            return
        }
        switch ProfileStart.decide(profiles: profiles, lastProfileID: highlightedID, askWhenSeveral: askWhenSeveral) {
        case .picker:
            phase = .picker
        case .use(let profile):
            select(profile)
        }
    }

    @discardableResult
    func load() async -> Bool {
        do {
            let list = try await repository.list()
            profiles = list.profiles
            maxProfiles = list.maxProfiles
            if let id = current?.id {
                current = profiles.first { $0.id == id }
            }
            return true
        } catch {
            Logger.network.error("Viewer profiles failed to load: \(String(describing: error), privacy: .public)")
            return false
        }
    }

    /// Makes `profile` the active one and opens the app.
    func select(_ profile: ViewerProfile?) {
        current = profile
        if let profile {
            store.set(profile.id, for: .viewerProfileId)
        } else {
            store.remove(.viewerProfileId)
        }
        phase = .ready
    }

    /// Profile tab → "Switch Profile".
    func showPicker() async {
        phase = .picker
        await load()
    }

    /// Back on "Who's Watching" when it was opened from the app.
    func cancelPicker() {
        guard canCancelPicker else { return }
        phase = .ready
    }

    /// Returns an error message, or nil on success.
    func create(name: String, avatar: String) async -> String? {
        do {
            let profile = try await repository.create(name: name, avatar: avatar)
            profiles.append(profile)
            return nil
        } catch {
            return Self.message(for: error)
        }
    }

    func update(_ profile: ViewerProfile, name: String?, avatar: String?) async -> String? {
        do {
            let updated = try await repository.update(id: profile.id, name: name, avatar: avatar)
            if let index = profiles.firstIndex(where: { $0.id == profile.id }) {
                profiles[index] = updated
            }
            if current?.id == profile.id {
                current = updated
            }
            return nil
        } catch {
            return Self.message(for: error)
        }
    }

    func delete(_ profile: ViewerProfile) async -> String? {
        do {
            try await repository.delete(id: profile.id)
            profiles.removeAll { $0.id == profile.id }
            if current?.id == profile.id || storedID == profile.id {
                current = nil
                store.remove(.viewerProfileId)
            }
            return nil
        } catch {
            return Self.message(for: error)
        }
    }

    /// The backend said the profile in use no longer exists (deleted on
    /// another device). `APIClient` already forgot the id; ask again.
    func profileWasDeleted() async {
        guard phase == .ready else { return }
        current = nil
        phase = .picker
        await load()
    }

    /// Sign-out: the next account starts fresh. (The Keychain id is cleared
    /// with the session keys.)
    func reset() {
        current = nil
        profiles = []
        phase = .deciding
    }

    private static func message(for error: any Error) -> String {
        (error as? APIError)?.userMessage ?? APIError.unknown.userMessage
    }
}
