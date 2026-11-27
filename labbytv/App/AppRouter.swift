import SwiftUI

/// Login → Playlist picker → "Who's Watching" (when needed) → Main tabs,
/// driven by `SessionStore` and `ViewerProfileStore`.
struct AppRouter: View {
    @Environment(AppEnvironment.self) private var environment
    @Environment(SessionStore.self) private var session

    var body: some View {
        Group {
            if !session.isLoggedIn {
                NavigationStack {
                    LoginView(viewModel: LoginViewModel(
                        repository: environment.authRepository,
                        session: session,
                        onSignedIn: { await environment.didSignIn() }
                    ))
                }
            } else if session.activePlaylist == nil {
                PlaylistPickerView(viewModel: PlaylistPickerViewModel(
                    repository: environment.playlistRepository,
                    session: session,
                    autoSelectSingle: true
                ))
            } else {
                switch profiles.phase {
                case .deciding:
                    LoadingView()
                        .task { await profiles.start() }
                case .picker:
                    NavigationStack {
                        WhoIsWatchingView(viewModel: WhoIsWatchingViewModel(store: profiles))
                    }
                case .ready:
                    // Rebuilt per playlist and per profile, so catalog state
                    // never mixes providers and history never mixes viewers.
                    MainTabView(environment: environment)
                        .id(MainTabIdentity(playlist: session.activePlaylist?.id, profile: profiles.current?.id))
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.background)
        .animation(.easeInOut(duration: 0.25), value: session.isLoggedIn)
        .animation(.easeInOut(duration: 0.25), value: session.activePlaylist?.id)
        .animation(.easeInOut(duration: 0.25), value: profiles.phase)
        .onChange(of: profiles.current?.id) {
            environment.viewerProfileDidChange()
        }
        // My List is kept per playlist.
        .onChange(of: session.activePlaylist?.id) {
            environment.myList.reset()
        }
        .onChange(of: session.isLoggedIn) { _, loggedIn in
            // Also covers the session expiring (refresh token rejected).
            if !loggedIn { profiles.reset() }
        }
    }

    private var profiles: ViewerProfileStore { environment.viewerProfiles }
}

private struct MainTabIdentity: Hashable {
    let playlist: String?
    let profile: String?
}

#if DEBUG
#Preview {
    let environment = AppEnvironment.preview(loggedIn: false, playlist: false)
    AppRouter()
        .environment(environment)
        .environment(environment.session)
        .environment(environment.premium)
        .environment(environment.playerPresenter)
        .environment(environment.channelFavorites)
        .environment(environment.livePreview)
}
#endif
