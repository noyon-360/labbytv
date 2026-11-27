import Foundation

/// A card on Home, for focus: the same title can sit in several rows.
nonisolated struct HomeCardID: Hashable, Sendable {
    enum Row: Hashable, Sendable {
        case favoriteChannels, continueWatching, recentlyWatched
        case popularMovies, popularSeries, recentMovies, recentSeries, myList
    }

    let row: Row
    let item: String
}
