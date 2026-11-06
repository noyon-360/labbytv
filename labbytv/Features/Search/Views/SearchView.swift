import SwiftUI

struct SearchView: View {
    @Environment(PlayerPresenter.self) private var player
    @Bindable var viewModel: SearchViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                if viewModel.isSearching && !viewModel.hasResults {
                    LoadingView(message: "Searching…").frame(height: 400)
                } else if let message = viewModel.errorMessage {
                    ErrorView(message: message, retry: { Task { await viewModel.search() } })
                        .frame(height: 500)
                } else if !viewModel.lastSearched.isEmpty && !viewModel.hasResults {
                    EmptyStateView(symbol: "magnifyingglass", title: "No results", message: "Nothing matches \"\(viewModel.lastSearched)\".")
                        .frame(height: 500)
                } else if viewModel.lastSearched.isEmpty {
                    EmptyStateView(symbol: "magnifyingglass", title: "Search LABBY TV", message: "Find channels, movies and series.")
                        .frame(height: 500)
                }

                if !viewModel.channels.isEmpty {
                    Shelf(title: "Channels") {
                        ForEach(viewModel.channels) { channel in
                            ChannelCard(channel: channel) {
                                player.play(.live(channel, lineup: viewModel.channels))
                            }
                        }
                    }
                }
                if !viewModel.movies.isEmpty {
                    Shelf(title: "Movies") {
                        ForEach(viewModel.movies) { movie in
                            NavigationLink(value: AppRoute.movie(movie)) {
                                PosterCard(title: movie.title, imageURL: movie.imageURL)
                            }
                            .buttonStyle(CardButtonStyle())
                        }
                    }
                }
                if !viewModel.series.isEmpty {
                    Shelf(title: "Series") {
                        ForEach(viewModel.series) { series in
                            NavigationLink(value: AppRoute.series(series)) {
                                PosterCard(title: series.title, imageURL: series.imageURL)
                            }
                            .buttonStyle(CardButtonStyle())
                        }
                    }
                }
            }
            .padding(.vertical, Spacing.l)
        }
        .scrollClipDisabled()
        .searchable(text: $viewModel.query, prompt: "Channels, movies, series")
        .task(id: viewModel.query) { await viewModel.search() }
        .onChange(of: viewModel.parentalLockChangeCount) {
            Task { await viewModel.applyParentalLockChanges() }
        }
    }
}

#if DEBUG
#Preview {
    let environment = AppEnvironment.preview()
    NavigationStack {
        SearchView(viewModel: SearchViewModel(catalog: MockCatalogRepository()))
            .appRouteDestinations()
    }
    .environment(environment)
    .environment(environment.playerPresenter)
}
#endif
