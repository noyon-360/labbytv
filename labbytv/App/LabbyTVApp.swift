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
        let environment = Self.makeEnvironment()
        if !Self.isMockRun {
            environment.premium.configure()
        }
        // Provider streams are plain http; without this, every stream fails with ATS -1022.
        Logger.player.notice("App Transport Security allows http streams: \(PlayerViewModel.allowsInsecureMedia, privacy: .public)")
        _environment = State(initialValue: environment)
    }

    /// Debug builds launched with `-UITestMockData` run on the preview mocks
    /// (signed in, Pro, Apple's sample HLS stream), so UI tests can drive the
    /// guide and player without a provider account. Not in release builds.
    private static func makeEnvironment() -> AppEnvironment {
        #if DEBUG
        if usesMockData { return .preview() }
        #endif
        return .live()
    }

    #if DEBUG
    private static var usesMockData: Bool { ProcessInfo.processInfo.arguments.contains("-UITestMockData") }
    #endif

    private static var isMockRun: Bool {
        #if DEBUG
        usesMockData
        #else
        false
        #endif
    }

    var body: some Scene {
        WindowGroup {
            AppRouter()
                .environment(environment)
                .environment(environment.session)
                .environment(environment.premium)
                .environment(environment.playerPresenter)
                .environment(environment.channelFavorites)
                .environment(environment.livePreview)
                .preferredColorScheme(.dark)
                .task {
                    // Cold start with a saved session: link RevenueCat and
                    // load the profile (subscription status, name).
                    #if DEBUG
                    // Mock run: no RevenueCat (keeps fake users out of the
                    // real project), just a Pro profile.
                    if Self.usesMockData {
                        environment.premium.update(from: MockData.premiumUser)
                        return
                    }
                    #endif
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
