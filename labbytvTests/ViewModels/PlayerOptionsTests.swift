import AVFoundation
import Foundation
import Testing
@testable import labbytv

@MainActor
struct PlayerOptionsTests {
    private func makeViewModel(_ item: PlayableItem, defaults: UserDefaults) -> PlayerViewModel {
        PlayerViewModel(item: item, catalog: MockCatalogRepository(), history: MockWatchHistoryRepository(), preferences: Preferences(defaults: defaults))
    }

    private func freshDefaults() -> UserDefaults {
        let name = "PlayerOptionsTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defaults.removePersistentDomain(forName: name)
        return defaults
    }

    @Test func speedLabels() {
        #expect(PlaybackSpeed.options.map(PlaybackSpeed.label(for:)) == ["0.5×", "0.75×", "1×", "1.25×", "1.5×", "2×"])
    }

    @Test func aspectModesMapToGravityAndVLCGeometry() {
        #expect(VideoAspectMode.fit.videoGravity == .resizeAspect)
        #expect(VideoAspectMode.fill.videoGravity == .resizeAspectFill)
        #expect(VideoAspectMode.stretch.videoGravity == .resize)
        #expect(VideoAspectMode.fit.vlcCropGeometry == nil && VideoAspectMode.fit.vlcAspectRatio == nil)
        #expect(VideoAspectMode.fill.vlcCropGeometry == "16:9" && VideoAspectMode.fill.vlcAspectRatio == nil)
        #expect(VideoAspectMode.stretch.vlcCropGeometry == nil && VideoAspectMode.stretch.vlcAspectRatio == "16:9")
    }

    @Test func aspectModeDefaultsToFitAndIsRemembered() {
        let defaults = freshDefaults()
        let movie = PlayableItem.movie(id: 1, title: "M", thumbnail: "")
        let first = makeViewModel(movie, defaults: defaults)
        #expect(first.aspectMode == .fit)
        first.setAspectMode(.stretch)
        #expect(makeViewModel(movie, defaults: defaults).aspectMode == .stretch)
    }

    @Test func liveTVIgnoresSpeedChanges() {
        let channel = Channel(id: 1, name: "A")
        let live = makeViewModel(.live(channel, lineup: [channel]), defaults: freshDefaults())
        #expect(!live.canChangeSpeed)
        live.setSpeed(2)
        #expect(live.speed == 1)

        let movie = makeViewModel(.movie(id: 1, title: "M", thumbnail: ""), defaults: freshDefaults())
        #expect(movie.canChangeSpeed)
        movie.setSpeed(1.5)
        #expect(movie.speed == 1.5)
    }
}
