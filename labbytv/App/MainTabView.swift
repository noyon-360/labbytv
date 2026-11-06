import SwiftUI

/// Sidebar tabs: Home, Live TV, Guide, Movies, Series, Search, Profile.
/// Each tab owns a NavigationStack, so Back/Menu pops within the tab and,
/// at a tab's root, falls through to the system (exit to the home screen).
struct MainTabView: View {
    private let environment: AppEnvironment
    @Bindable private var player: PlayerPresenter

    @State private var selection: AppTab = .home
    @State private var home: HomeViewModel
    @State private var live: CatalogViewModel<Channel>
    @State private var guide: GuideViewModel
    @State private var movies: CatalogViewModel<Movie>
    @State private var series: CatalogViewModel<Series>
    @State private var search: SearchViewModel
    @State private var profile: ProfileViewModel

    init(environment: AppEnvironment) {
        self.environment = environment
        player = environment.playerPresenter
        let catalog = environment.catalogRepository
        let lock = environment.parentalLock
        _home = State(initialValue: HomeViewModel(catalog: catalog, history: environment.historyRepository, preferences: environment.preferences, parentalLock: lock))
        _live = State(initialValue: CatalogViewModel(type: .channels, repository: catalog, parentalLock: lock))
        _guide = State(initialValue: GuideViewModel(channels: CatalogViewModel(type: .channels, repository: catalog, parentalLock: lock, pageSize: 30), cache: environment.epgCache))
        _movies = State(initialValue: CatalogViewModel(type: .movies, repository: catalog, parentalLock: lock))
        _series = State(initialValue: CatalogViewModel(type: .series, repository: catalog, parentalLock: lock))
        _search = State(initialValue: SearchViewModel(catalog: catalog, parentalLock: lock))
        _profile = State(initialValue: ProfileViewModel(environment: environment))
    }

    var body: some View {
        tabs
            .pinPrompt(environment.parentalLock)
            .fullScreenCover(item: $player.current) { item in
                PlayerView(
                    viewModel: PlayerViewModel(item: item, catalog: environment.catalogRepository, history: environment.historyRepository, preferences: environment.preferences),
                    showsWatermark: !environment.premium.isPremium,
                    onClose: { player.close() }
                )
            }
    }

    @ViewBuilder
    private var tabs: some View {
        if #available(tvOS 18, *) {
            TabView(selection: $selection) {
                ForEach(AppTab.allCases) { tab in
                    Tab(tab.title, systemImage: tab.symbol, value: tab, role: tab == .search ? .search : nil) {
                        stack(for: tab)
                    }
                }
            }
            .tabViewStyle(.sidebarAdaptable)
        } else {
            // tvOS 17: top tab bar.
            TabView(selection: $selection) {
                ForEach(AppTab.allCases) { tab in
                    stack(for: tab)
                        .tabItem { Label(tab.title, systemImage: tab.symbol) }
                        .tag(tab)
                }
            }
        }
    }

    private func stack(for tab: AppTab) -> some View {
        NavigationStack {
            content(for: tab)
                .appRouteDestinations()
        }
    }

    @ViewBuilder
    private func content(for tab: AppTab) -> some View {
        switch tab {
        case .home: HomeView(viewModel: home)
        case .live: LiveTVView(viewModel: live)
        case .guide: GuideView(viewModel: guide)
        case .movies: MoviesView(viewModel: movies)
        case .series: SeriesView(viewModel: series)
        case .search: SearchView(viewModel: search)
        case .profile: ProfileView(viewModel: profile)
        }
    }
}

#if DEBUG
#Preview {
    let environment = AppEnvironment.preview()
    MainTabView(environment: environment)
        .environment(environment)
        .environment(environment.session)
        .environment(environment.premium)
        .environment(environment.playerPresenter)
}
#endif
