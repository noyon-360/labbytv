import SwiftUI

/// Builds the screen for an `AppRoute`, wiring view models to the shared services.
struct AppRouteDestination: View {
    @Environment(AppEnvironment.self) private var environment
    let route: AppRoute

    var body: some View {
        switch route {
        case .movie(let movie):
            MovieDetailView(viewModel: MovieDetailViewModel(movie: movie, catalog: environment.catalogRepository, history: environment.historyRepository))
        case .series(let series):
            SeriesDetailView(viewModel: SeriesDetailViewModel(series: series, catalog: environment.catalogRepository, history: environment.historyRepository))
        case .playlists:
            PlaylistPickerView(
                viewModel: PlaylistPickerViewModel(repository: environment.playlistRepository, session: environment.session, autoSelectSingle: false),
                dismissOnSelect: true
            )
        case .favorites:
            WatchHistoryView(viewModel: FavoritesViewModel(mode: .favorites, repository: environment.historyRepository, preferences: environment.preferences))
        case .history:
            WatchHistoryView(viewModel: FavoritesViewModel(mode: .history, repository: environment.historyRepository, preferences: environment.preferences))
        case .legal(let document):
            LegalTextView(document: document)
        case .paywall:
            PaywallView(viewModel: PaywallViewModel(premium: environment.premium, onPurchased: { await environment.refreshProfile() }))
        }
    }
}

extension View {
    /// Registers `AppRoute` destinations on a tab's `NavigationStack`.
    func appRouteDestinations() -> some View {
        navigationDestination(for: AppRoute.self) { route in
            AppRouteDestination(route: route)
        }
    }
}
