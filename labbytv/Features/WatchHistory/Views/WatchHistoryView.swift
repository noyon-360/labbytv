import SwiftUI

struct WatchHistoryView: View {
    @Environment(PlayerPresenter.self) private var player
    @State private var viewModel: FavoritesViewModel
    @State private var unavailableItem: WatchHistoryItem?

    init(viewModel: FavoritesViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.l) {
            Text(viewModel.mode.title)
                .font(AppFonts.title)
                .foregroundStyle(AppColors.textPrimary)
            content
        }
        .padding(.top, Spacing.l)
        .task { await viewModel.load() }
        .alert("Can't open this item", isPresented: Binding(get: { unavailableItem != nil }, set: { if !$0 { unavailableItem = nil } })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Open the series from the Series tab to keep watching.")
        }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading && viewModel.items.isEmpty {
            LoadingView()
        } else if let message = viewModel.errorMessage {
            ErrorView(message: message, retry: { Task { await viewModel.load() } })
        } else if viewModel.items.isEmpty {
            EmptyStateView(
                symbol: viewModel.mode == .favorites ? "heart" : "clock",
                title: viewModel.mode == .favorites ? "No favorites yet" : "Nothing watched yet",
                message: viewModel.mode == .favorites ? "Add movies and series to your favorites from their detail page." : nil
            )
        } else {
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: Spacing.gridSpacing, alignment: .top), count: 6), spacing: Spacing.xl) {
                    ForEach(viewModel.items) { item in
                        cell(for: item)
                            .onAppear { Task { await viewModel.loadMoreIfNeeded(after: item) } }
                    }
                }
                .padding(.vertical, Spacing.m)
            }
            .scrollClipDisabled()
        }
    }

    @ViewBuilder
    private func cell(for item: WatchHistoryItem) -> some View {
        let subtitle = item.videoType == "live" ? "Live TV" : (item.seasonNumber.map { "S\($0) E\(item.episodeNumber ?? 0)" } ?? item.videoType.capitalized)
        let card = PosterCard(title: item.name, imageURL: item.imageURL, subtitle: subtitle, progress: viewModel.mode == .history && item.videoType != "live" ? item.progress : nil)
        switch viewModel.destination(for: item) {
        case .route(let route):
            NavigationLink(value: route) { card }
                .buttonStyle(CardButtonStyle())
        case .play(let playable):
            Button { player.play(playable) } label: { card }
                .buttonStyle(CardButtonStyle())
        case .unavailable:
            Button { unavailableItem = item } label: { card }
                .buttonStyle(CardButtonStyle())
        }
    }
}

#if DEBUG
#Preview {
    let environment = AppEnvironment.preview()
    NavigationStack {
        WatchHistoryView(viewModel: FavoritesViewModel(mode: .history, repository: MockWatchHistoryRepository(), preferences: environment.preferences))
            .appRouteDestinations()
    }
    .environment(environment)
    .environment(environment.playerPresenter)
}
#endif
