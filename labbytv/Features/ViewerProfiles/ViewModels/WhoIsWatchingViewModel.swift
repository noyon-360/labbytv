import Foundation
import Observation

@MainActor
@Observable
final class WhoIsWatchingViewModel {
    /// Manage mode: choosing a tile edits it instead of opening the app.
    var isManaging = false

    @ObservationIgnored let store: ViewerProfileStore

    init(store: ViewerProfileStore) {
        self.store = store
    }

    var profiles: [ViewerProfile] { store.profiles }
    var canAddProfile: Bool { store.canAddProfile }
    var title: String { isManaging ? "Manage Profiles" : "Who's watching?" }

    /// Initial focus: the profile this device used last, else the main one.
    var initialFocusID: String? {
        let highlighted = store.highlightedID
        if let highlighted, profiles.contains(where: { $0.id == highlighted }) {
            return highlighted
        }
        return profiles.first(where: \.isDefault)?.id ?? profiles.first?.id
    }

    func choose(_ profile: ViewerProfile) {
        store.select(profile)
    }

    /// What Back does here: leave manage mode, or return to the app when
    /// opened from Switch Profile. `nil` lets the system exit the app.
    var backAction: (() -> Void)? {
        if isManaging {
            return { [weak self] in self?.isManaging = false }
        }
        if store.canCancelPicker {
            return { [weak self] in self?.store.cancelPicker() }
        }
        return nil
    }

    func reload() async {
        await store.load()
    }
}
