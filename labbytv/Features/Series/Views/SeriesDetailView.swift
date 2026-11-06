import SwiftUI

struct SeriesDetailView: View {
    @Environment(PlayerPresenter.self) private var player
    @State private var viewModel: SeriesDetailViewModel

    init(viewModel: SeriesDetailViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        ZStack {
            DetailBackdrop(url: viewModel.info?.backdropURL ?? viewModel.series.imageURL)

            if viewModel.isLoading && viewModel.info == nil {
                LoadingView()
            } else if let message = viewModel.errorMessage, viewModel.info == nil {
                ErrorView(message: message, retry: { Task { await viewModel.load() } })
            } else {
                content
            }
        }
        .task { await viewModel.load() }
    }

    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.l) {
                header

                if viewModel.seasons.isEmpty {
                    EmptyStateView(symbol: "tv", title: "No episodes yet", message: "This provider hasn't listed any episodes for this series.")
                        .frame(height: 300)
                } else {
                    seasonChips
                    LazyVStack(spacing: Spacing.m) {
                        ForEach(viewModel.episodes) { episode in
                            EpisodeRow(episode: episode, fallbackImage: URL(xtreamImage: viewModel.cover)) {
                                player.play(.episode(episode, context: viewModel.context))
                            }
                        }
                    }
                    .focusSection()
                }
            }
            .padding(.vertical, Spacing.l)
        }
        .scrollClipDisabled()
    }

    private var header: some View {
        HStack(alignment: .top, spacing: Spacing.xl) {
            RemoteImage(url: URL(xtreamImage: viewModel.cover), placeholderSymbol: "tv")
                .frame(width: 300, height: 450)
                .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerRadius, style: .continuous))

            VStack(alignment: .leading, spacing: Spacing.m) {
                Text(viewModel.title)
                    .font(AppFonts.title)
                    .lineLimit(2)
                let meta = [String(viewModel.info?.releaseDate.prefix(4) ?? ""), viewModel.info?.genre ?? ""].filter { !$0.isEmpty }
                if !meta.isEmpty {
                    Text(meta.joined(separator: "  ·  "))
                        .font(AppFonts.caption)
                        .foregroundStyle(AppColors.textSecondary)
                }
                if let plot = viewModel.info?.plot, !plot.isEmpty {
                    Text(plot).lineLimit(4).foregroundStyle(AppColors.textSecondary)
                }
                if let cast = viewModel.info?.cast, !cast.isEmpty {
                    Text("Cast: \(cast)").font(AppFonts.caption).foregroundStyle(AppColors.textSecondary).lineLimit(2)
                }
                HStack(spacing: Spacing.m) {
                    if let first = viewModel.episodes.first {
                        Button {
                            player.play(.episode(first, context: viewModel.context))
                        } label: {
                            Label("Play S\(first.season) E\(first.episodeNum)", systemImage: "play.fill")
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .frame(width: 420)
                    }
                    Button {
                        Task { await viewModel.toggleFavorite() }
                    } label: {
                        Label(viewModel.isFavorite ? "In Favorites" : "Add to Favorites", systemImage: viewModel.isFavorite ? "heart.fill" : "heart")
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
                .focusSection()
            }
            .font(AppFonts.body)
            .foregroundStyle(AppColors.textPrimary)
        }
    }

    private var seasonChips: some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: Spacing.s) {
                ForEach(viewModel.seasons) { season in
                    Button(season.name.isEmpty ? "Season \(season.seasonNumber)" : season.name) {
                        viewModel.selectSeason(season.seasonNumber)
                    }
                    .buttonStyle(ChipButtonStyle(isSelected: season.seasonNumber == viewModel.selectedSeason))
                }
            }
            .padding(.vertical, Spacing.s)
        }
        .scrollClipDisabled()
        .focusSection()
    }
}

#if DEBUG
#Preview {
    let environment = AppEnvironment.preview()
    SeriesDetailView(viewModel: SeriesDetailViewModel(series: MockData.series[0], catalog: MockCatalogRepository(), history: MockWatchHistoryRepository()))
        .environment(environment.playerPresenter)
}
#endif
