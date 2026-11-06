import Foundation

/// Pushed screens inside a tab's `NavigationStack`.
nonisolated enum AppRoute: Hashable, Sendable {
    case movie(Movie)
    case series(Series)
    case playlists
    case favorites
    case history
    case legal(LegalDocument)
    case paywall
}
