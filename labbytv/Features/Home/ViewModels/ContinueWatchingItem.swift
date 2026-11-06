import Foundation

nonisolated struct ContinueWatchingItem: Identifiable, Hashable, Sendable {
    let history: WatchHistoryItem
    let playable: PlayableItem

    var id: String { history.id }
}
