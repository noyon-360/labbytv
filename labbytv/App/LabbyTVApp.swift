import SwiftUI
import os

@main
struct LabbyTVApp: App {
    @State private var environment: AppEnvironment
    @Environment(\.scenePhase) private var scenePhase

    init() {
        // AsyncImage goes through URLSession.shared; a bigger cache keeps
        // posters and logos from reloading while scrolling grids.
        URLCache.shared = URLCache(memoryCapacity: 64 * 1024 * 1024, diskCapacity: 512 * 1024 * 1024)
        let environment = AppEnvironment.live()
        environment.premium.configure()
        // Provider streams are plain http; without this, every stream fails with ATS -1022.
        Logger.player.notice("App Transport Security allows http streams: \(PlayerViewModel.allowsInsecureMedia, privacy: .public)")
        _environment = State(initialValue: environment)
    }

    var body: some Scene {
        WindowGroup {
            AppRouter()
                .environment(environment)
                .environment(environment.session)
                .environment(environment.premium)
                .environment(environment.playerPresenter)
                .preferredColorScheme(.dark)
                .task {
                    // Cold start with a saved session: link RevenueCat and
                    // load the profile (subscription status, name).
                    if environment.session.isLoggedIn {
                        await environment.didSignIn()
                    }
                }
                // Every PIN unlock ends when the user leaves the app (Flutter
                // relocks on `AppLifecycleState.paused`).
                .onChange(of: scenePhase) { _, phase in
                    if phase == .background {
                        environment.parentalLock.relock()
                    }
                }
        }
    }
}
