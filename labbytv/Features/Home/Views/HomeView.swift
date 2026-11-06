import SwiftUI

struct HomeView: View {
    @Environment(PlayerPresenter.self) private var player
    let viewModel: HomeViewModel

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.isEmpty {
                LoadingView()
            } else if let message = viewModel.errorMessage {
                ErrorView(message: message, retry: { Task { await viewModel.load() } })
            } else {
                content
            }
        }
        .task {
            if viewModel.isEmpty { await viewModel.load() }
        }
        // Refresh Continue Watching when the player closes.
        .onChange(of: player.current) { old, new in
            if old != nil && new == nil {
                Task { await viewModel.load() }
            }
        }
    }

    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                if !viewModel.continueWatching.isEmpty {
                    Shelf(title: "Continue Watching") {
                        ForEach(viewModel.continueWatching) { item in
                            Button {
                                player.play(item.playable)
                            } label: {
                                PosterCard(title: item.history.name, imageURL: item.history.imageURL, progress: item.history.progress)
                            }
                            .buttonStyle(CardButtonStyle())
                        }
                    }
                }
                if !viewModel.movies.isEmpty {
                    Shelf(title: "Popular Movies") {
                        ForEach(viewModel.movies) { movie in
                            NavigationLink(value: AppRoute.movie(movie)) {
                                PosterCard(title: movie.title, imageURL: movie.imageURL)
                            }
                            .buttonStyle(CardButtonStyle())
                        }
                    }
                }
                if !viewModel.series.isEmpty {
                    Shelf(title: "Popular Series") {
                        ForEach(viewModel.series) { series in
                            NavigationLink(value: AppRoute.series(series)) {
                                PosterCard(title: series.title, imageURL: series.imageURL)
                            }
                            .buttonStyle(CardButtonStyle())
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
}

#if DEBUG
#Preview {
    let environment = AppEnvironment.preview()
    NavigationStack {
        HomeView(viewModel: HomeViewModel(catalog: MockCatalogRepository(), history: MockWatchHistoryRepository(), preferences: environment.preferences))
            .appRouteDestinations()
    }
    .environment(environment)
    .environment(environment.playerPresenter)
}
#endif
