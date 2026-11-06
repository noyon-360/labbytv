import SwiftUI

/// Login → Playlist picker → Main tabs, driven by `SessionStore`.
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
                // Rebuilt per playlist so catalog state never mixes providers.
                MainTabView(environment: environment)
                    .id(session.activePlaylist?.id)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.background)
        .animation(.easeInOut(duration: 0.25), value: session.isLoggedIn)
        .animation(.easeInOut(duration: 0.25), value: session.activePlaylist?.id)
    }
}

#if DEBUG
#Preview {
    let environment = AppEnvironment.preview(loggedIn: false, playlist: false)
    AppRouter()
        .environment(environment)
        .environment(environment.session)
        .environment(environment.premium)
        .environment(environment.playerPresenter)
}
#endif
