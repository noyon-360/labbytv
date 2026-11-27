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
    @ObservationIgnored let parentalLock: ParentalLockService

    @ObservationIgnored let authRepository: any AuthRepository
    @ObservationIgnored let playlistRepository: any PlaylistRepository
    @ObservationIgnored let catalogRepository: any CatalogRepository
    @ObservationIgnored let epgCache: EPGCache
    @ObservationIgnored let historyRepository: any WatchHistoryRepository
    @ObservationIgnored let profileRepository: any ProfileRepository
    @ObservationIgnored let channelFavorites: ChannelFavorites
    @ObservationIgnored let livePreview: LivePreview
    @ObservationIgnored let viewerProfiles: ViewerProfileStore
    @ObservationIgnored let categoryNames: CategoryNames
    @ObservationIgnored let watchLaterRepository: any WatchLaterRepository
    @ObservationIgnored let myList: MyList

    init(
        session: SessionStore,
        store: any SecureStore,
        premium: PremiumService,
        preferences: Preferences,
        authRepository: any AuthRepository,
        playlistRepository: any PlaylistRepository,
        catalogRepository: any CatalogRepository,
        epgRepository: any EPGRepository,
        historyRepository: any WatchHistoryRepository,
        profileRepository: any ProfileRepository,
        viewerProfileRepository: any ViewerProfileRepository,
        watchLaterRepository: any WatchLaterRepository,
        categoryNames: CategoryNames? = nil
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
        self.channelFavorites = ChannelFavorites(repository: historyRepository)
        self.livePreview = LivePreview(catalog: catalogRepository)
        self.parentalLock = ParentalLockService(store: store, preferences: preferences, profile: profileRepository)
        self.viewerProfiles = ViewerProfileStore(repository: viewerProfileRepository, store: store)
        self.watchLaterRepository = watchLaterRepository
        self.myList = MyList(repository: watchLaterRepository)
        self.categoryNames = categoryNames ?? CategoryNames(catalog: catalogRepository) { [weak session] in
            await session?.activePlaylist?.id
        }
    }

    /// The real app: Keychain, live backend.
    static func live() -> AppEnvironment {
        let store = KeychainStore()
        let session = SessionStore(store: store)
        let premium = PremiumService()
        // The client is built before the profile store it reports to.
        let profileGone = ProfileGoneRelay()
        let client = APIClient(
            store: store,
            onSessionExpired: { [weak session, weak premium] in
                await premium?.logOut()
                await session?.signOut()
            },
            onProfileGone: { await profileGone.notify() }
        )
        // Repositories are nonisolated; they read the active playlist from
        // the main-actor session on demand.
        let credentials: @Sendable () async -> ServerCredentials? = { [weak session] in
            await session?.credentials
        }
        let catalog = CatalogRepositoryLive(client: client, credentials: credentials)
        let categoryNames = CategoryNames(catalog: catalog) { [weak session] in
            await session?.activePlaylist?.id
        }
        let environment = AppEnvironment(
            session: session,
            store: store,
            premium: premium,
            preferences: Preferences(),
            authRepository: AuthRepositoryLive(client: client, store: store),
            playlistRepository: PlaylistRepositoryLive(client: client),
            catalogRepository: catalog,
            epgRepository: EPGRepositoryLive(client: client, credentials: credentials),
            historyRepository: WatchHistoryRepositoryLive(client: client, categoryNames: categoryNames),
            profileRepository: ProfileRepositoryLive(client: client),
            viewerProfileRepository: ViewerProfileRepositoryLive(client: client),
            watchLaterRepository: WatchLaterRepositoryLive(client: client) { [weak session] in
                await session?.activePlaylist?.id
            },
            categoryNames: categoryNames
        )
        profileGone.store = environment.viewerProfiles
        return environment
    }

    /// Signs out everywhere: RevenueCat, then the local session.
    func signOut() async {
        await premium.logOut()
        await epgCache.clear()
        livePreview.stop()
        channelFavorites.reset()
        myList.reset()
        viewerProfiles.reset()
        session.signOut()
    }

    /// History, favourites and Continue Watching belong to the profile, so
    /// drop what the previous one loaded.
    func viewerProfileDidChange() {
        livePreview.stop()
        channelFavorites.reset()
        myList.reset()
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

    /// Hands the client's "profile gone" callback to the store once it exists.
    @MainActor
    private final class ProfileGoneRelay {
        weak var store: ViewerProfileStore?

        func notify() async {
            await store?.profileWasDeleted()
        }
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
            store: store,
            premium: PremiumService(),
            preferences: Preferences(defaults: UserDefaults(suiteName: "preview") ?? .standard),
            authRepository: MockAuthRepository(),
            playlistRepository: MockPlaylistRepository(),
            catalogRepository: MockCatalogRepository(),
            epgRepository: MockEPGRepository(),
            historyRepository: MockWatchHistoryRepository(),
            profileRepository: MockProfileRepository(),
            viewerProfileRepository: MockViewerProfileRepository(),
            watchLaterRepository: MockWatchLaterRepository()
        )
    }
    #endif
}
