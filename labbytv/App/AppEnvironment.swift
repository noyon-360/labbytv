import Foundation
import Observation

/// Builds the shared services once. Injected with `.environment(...)`.
@MainActor
@Observable
final class AppEnvironment {
    @ObservationIgnored let session: SessionStore
    @ObservationIgnored let premium: PremiumService
    @ObservationIgnored let playerPresenter: PlayerPresenter
    @ObservationIgnored let preferences: Preferences

    @ObservationIgnored let authRepository: any AuthRepository
    @ObservationIgnored let playlistRepository: any PlaylistRepository
    @ObservationIgnored let catalogRepository: any CatalogRepository
    @ObservationIgnored let epgCache: EPGCache
    @ObservationIgnored let historyRepository: any WatchHistoryRepository
    @ObservationIgnored let profileRepository: any ProfileRepository

    init(
        session: SessionStore,
        premium: PremiumService,
        preferences: Preferences,
        authRepository: any AuthRepository,
        playlistRepository: any PlaylistRepository,
        catalogRepository: any CatalogRepository,
        epgRepository: any EPGRepository,
        historyRepository: any WatchHistoryRepository,
        profileRepository: any ProfileRepository
    ) {
        self.session = session
        self.premium = premium
        self.preferences = preferences
        self.playerPresenter = PlayerPresenter()
        self.authRepository = authRepository
        self.playlistRepository = playlistRepository
        self.catalogRepository = catalogRepository
        self.epgCache = EPGCache(repository: epgRepository)
        self.historyRepository = historyRepository
        self.profileRepository = profileRepository
    }

    /// The real app: Keychain, live backend.
    static func live() -> AppEnvironment {
        let store = KeychainStore()
        let session = SessionStore(store: store)
        let premium = PremiumService()
        let client = APIClient(store: store) { [weak session, weak premium] in
            await premium?.logOut()
            await session?.signOut()
        }
        // Repositories are nonisolated; they read the active playlist from
        // the main-actor session on demand.
        let credentials: @Sendable () async -> ServerCredentials? = { [weak session] in
            await session?.credentials
        }
        return AppEnvironment(
            session: session,
            premium: premium,
            preferences: Preferences(),
            authRepository: AuthRepositoryLive(client: client, store: store),
            playlistRepository: PlaylistRepositoryLive(client: client),
            catalogRepository: CatalogRepositoryLive(client: client, credentials: credentials),
            epgRepository: EPGRepositoryLive(client: client, credentials: credentials),
            historyRepository: WatchHistoryRepositoryLive(client: client),
            profileRepository: ProfileRepositoryLive(client: client)
        )
    }

    /// Signs out everywhere: RevenueCat, then the local session.
    func signOut() async {
        await premium.logOut()
        await epgCache.clear()
        session.signOut()
    }

    /// After login or register: link RevenueCat and load the profile.
    func didSignIn() async {
        if let userID = session.userId {
            await premium.logIn(userID: userID)
        }
        await refreshProfile()
    }

    func refreshProfile() async {
        guard let user = try? await profileRepository.profile() else { return }
        session.updateUser(user)
        premium.update(from: user)
    }

    #if DEBUG
    static func preview(loggedIn: Bool = true, playlist: Bool = true) -> AppEnvironment {
        let store = InMemorySecureStore()
        let session = SessionStore(store: store)
        if loggedIn {
            try? session.signIn(with: MockData.loginResponse)
        }
        if playlist {
            session.selectPlaylist(MockData.playlists[0])
        }
        return AppEnvironment(
            session: session,
            premium: PremiumService(),
            preferences: Preferences(defaults: UserDefaults(suiteName: "preview") ?? .standard),
            authRepository: MockAuthRepository(),
            playlistRepository: MockPlaylistRepository(),
            catalogRepository: MockCatalogRepository(),
            epgRepository: MockEPGRepository(),
            historyRepository: MockWatchHistoryRepository(),
            profileRepository: MockProfileRepository()
        )
    }
    #endif
}
