import SwiftUI

struct HomeView: View {
    @Environment(PlayerPresenter.self) private var player
    let viewModel: HomeViewModel
    @FocusState private var focus: HomeCardID?
    /// Where focus was, so it can be put back near there when that card
    /// is gone (removed from My List or Favorites, or a finished movie).
    @State private var lastFocus: HomeCardID?
    @State private var lastFocusIndex = 0
    /// Where focus was when it left Home's cards. On a tvOS push neither
    /// `onDisappear` nor `onAppear` fires, so focus changes are the signal.
    @State private var leftAt: (card: HomeCardID, index: Int)?

    var body: some View {
        Group {
            if viewModel.isEmpty && (viewModel.isLoading || !viewModel.hasLoaded) {
                LoadingView(message: "Loading your playlist…")
            } else if let message = viewModel.errorMessage {
                ErrorView(message: message, retry: { Task { await viewModel.load() } })
            } else {
                content
            }
        }
        .task {
            await viewModel.applyParentalLockChanges()
            if viewModel.isEmpty { await viewModel.load() }
        }
        .onChange(of: viewModel.parentalLockChangeCount) {
            Task { await viewModel.applyParentalLockChanges() }
        }
        // Refresh Continue Watching when the player closes.
        .onChange(of: player.current) { old, new in
            if old != nil && new == nil {
                Task {
                    await viewModel.load()
                    // The reload can take the card away after focus came back.
                    if focus == nil, let lastFocus { move(from: lastFocus, index: lastFocusIndex) }
                }
            }
        }
        .onChange(of: focus) { old, new in
            guard let new else {
                // Focus left Home's cards: a page opened, the player, or the sidebar.
                if let old { leftAt = (old, lastFocusIndex) }
                return
            }
            if let (card, index) = leftAt {
                leftAt = nil
                // Back on Home but the card that was open has left its row,
                // so tvOS picked one in another row (or none). Put focus
                // near where the user was instead.
                if !contains(card) && new.row != card.row {
                    move(from: card, index: index)
                    return
                }
            }
            lastFocus = new
            lastFocusIndex = rows.first { $0.row == new.row }?.items.firstIndex(of: new.item) ?? 0
        }
    }

    private func contains(_ card: HomeCardID) -> Bool {
        rows.first { $0.row == card.row }?.items.contains(card.item) ?? false
    }

    /// Row order on screen, for finding a neighbour.
    private var rows: [(row: HomeCardID.Row, items: [String])] {
        [
            (.favoriteChannels, viewModel.favoriteChannels.map { String($0.id) }),
            (.continueWatching, viewModel.continueWatching.map(\.id)),
            (.recentlyWatched, viewModel.recentlyWatched.filter(isOpenable).map(\.id)),
            (.popularMovies, viewModel.movies.map { String($0.id) }),
            (.popularSeries, viewModel.series.map { String($0.id) }),
            (.recentMovies, viewModel.recentlyAddedMovies.map { String($0.id) }),
            (.recentSeries, viewModel.recentlyAddedSeries.map { String($0.id) }),
            (.myList, viewModel.myListItems.map(\.id)),
        ]
    }

    private func isOpenable(_ item: WatchHistoryItem) -> Bool {
        if case .unavailable = viewModel.destination(for: item) { return false }
        return true
    }

    /// Focus the card now at `index` in the same row, else the first card
    /// of the nearest row above, else below.
    private func move(from card: HomeCardID, index: Int) {
        let rows = rows
        guard let rowIndex = rows.firstIndex(where: { $0.row == card.row }) else { return }
        let items = rows[rowIndex].items
        if !items.isEmpty {
            focus = HomeCardID(row: card.row, item: items[min(index, items.count - 1)])
            return
        }
        let others = rows[..<rowIndex].reversed() + rows[(rowIndex + 1)...]
        if let next = others.first(where: { !$0.items.isEmpty }), let first = next.items.first {
            focus = HomeCardID(row: next.row, item: first)
        }
    }

    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                if !viewModel.favoriteChannels.isEmpty {
                    Shelf(title: "Favorite Channels") {
                        ForEach(viewModel.favoriteChannels) { channel in
                            // Lineup = the favourites, so up/down in the
                            // player surfs them.
                            ChannelCard(channel: channel, isFavorite: true) {
                                player.play(.live(channel, lineup: viewModel.favoriteChannels))
                            }
                            .focused($focus, equals: HomeCardID(row: .favoriteChannels, item: String(channel.id)))
                        }
                    }
                }
                if !viewModel.continueWatching.isEmpty {
                    Shelf(title: "Continue Watching") {
                        ForEach(viewModel.continueWatching) { item in
                            Button {
                                player.play(item.playable)
                            } label: {
                                PosterCard(title: item.history.name, imageURL: item.history.imageURL, subtitle: item.history.categoryName, progress: item.history.progress)
                            }
                            .buttonStyle(CardButtonStyle())
                            .focused($focus, equals: HomeCardID(row: .continueWatching, item: item.id))
                        }
                    }
                }
                if !viewModel.recentlyWatched.isEmpty {
                    Shelf(title: "Recently Watched") {
                        ForEach(viewModel.recentlyWatched) { item in
                            recentlyWatchedCard(item)
                                .focused($focus, equals: HomeCardID(row: .recentlyWatched, item: item.id))
                        }
                    }
                }
                if !viewModel.movies.isEmpty {
                    Shelf(title: "Popular Movies") {
                        ForEach(viewModel.movies) { movie in
                            movieLink(movie, row: .popularMovies)
                        }
                    }
                }
                if !viewModel.series.isEmpty {
                    Shelf(title: "Popular Series") {
                        ForEach(viewModel.series) { series in
                            seriesLink(series, row: .popularSeries)
                        }
                    }
                }
                if !viewModel.recentlyAddedMovies.isEmpty {
                    Shelf(title: "Recently Added Movies") {
                        ForEach(viewModel.recentlyAddedMovies) { movie in
                            movieLink(movie, row: .recentMovies)
                        }
                    }
                }
                if !viewModel.recentlyAddedSeries.isEmpty {
                    Shelf(title: "Recently Added TV Shows") {
                        ForEach(viewModel.recentlyAddedSeries) { series in
                            seriesLink(series, row: .recentSeries)
                        }
                    }
                }
                if !viewModel.myListItems.isEmpty {
                    Shelf(title: "My List") {
                        ForEach(viewModel.myListItems) { item in
                            if let route = item.route {
                                NavigationLink(value: route) {
                                    PosterCard(title: item.title, imageURL: item.imageURL, subtitle: item.isSeries ? "Series" : "Movie")
                                }
                                .buttonStyle(CardButtonStyle())
                                .focused($focus, equals: HomeCardID(row: .myList, item: item.id))
                            }
                        }
                    }
                }
                if viewModel.isEmpty {
                    EmptyStateView(symbol: "sparkles.tv", title: "Nothing to show yet", message: "Your playlist didn't return any movies or series.")
                        .frame(height: 500)
                }
            }
            .padding(.vertical, Spacing.l)
        }
        .scrollClipDisabled()
    }

    private func movieLink(_ movie: Movie, row: HomeCardID.Row) -> some View {
        NavigationLink(value: AppRoute.movie(movie)) {
            PosterCard(title: movie.title, imageURL: movie.imageURL, subtitle: "Movie", badge: RatingBadge.text(movie.rating5Based))
        }
        .buttonStyle(CardButtonStyle())
        .focused($focus, equals: HomeCardID(row: row, item: String(movie.id)))
    }

    private func seriesLink(_ series: Series, row: HomeCardID.Row) -> some View {
        NavigationLink(value: AppRoute.series(series)) {
            PosterCard(title: series.title, imageURL: series.imageURL, subtitle: "Series", badge: RatingBadge.text(series.rating5Based))
        }
        .buttonStyle(CardButtonStyle())
        .focused($focus, equals: HomeCardID(row: row, item: String(series.id)))
    }

    @ViewBuilder
    private func recentlyWatchedCard(_ item: WatchHistoryItem) -> some View {
        let card = PosterCard(title: item.name, imageURL: item.imageURL, subtitle: HomeRows.caption(for: item))
        switch viewModel.destination(for: item) {
        case .route(let route):
            NavigationLink(value: route) { card }
                .buttonStyle(CardButtonStyle())
        case .play(let playable):
            Button { player.play(playable) } label: { card }
                .buttonStyle(CardButtonStyle())
        case .unavailable:
            // Episode played on another device: this TV can't map it back
            // to its series, so leave it out rather than show a dead card.
            EmptyView()
        }
    }
}

#if DEBUG
#Preview {
    let environment = AppEnvironment.preview()
    NavigationStack {
        HomeView(viewModel: HomeViewModel(catalog: MockCatalogRepository(), history: MockWatchHistoryRepository(), preferences: environment.preferences, channelFavorites: environment.channelFavorites, myList: environment.myList))
            .appRouteDestinations()
    }
    .environment(environment)
    .environment(environment.playerPresenter)
}
#endif
