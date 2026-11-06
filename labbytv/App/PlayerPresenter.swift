import Foundation
import Observation

/// Any screen asks this to play something; `MainTabView` presents the
/// full-screen player for `current`.
@MainActor
@Observable
final class PlayerPresenter {
    var current: PlayableItem?

    func play(_ item: PlayableItem) {
        current = item
    }

    func close() {
        current = nil
    }
}
