import SwiftUI

struct MovieDetailView: View {
    @Environment(PlayerPresenter.self) private var player
    @State private var viewModel: MovieDetailViewModel
    @FocusState private var playFocused: Bool

    init(viewModel: MovieDetailViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        ZStack {
            DetailBackdrop(url: viewModel.info?.backdropURL ?? viewModel.posterURL)

            if viewModel.isLoading && viewModel.info == nil {
                LoadingView()
            } else {
                content
            }
        }
        .task { await viewModel.load() }
        .onChange(of: player.current) { old, new in
            if old != nil && new == nil {
                Task { await viewModel.refreshStatus() }
            }
        }
    }

    private var content: some View {
        HStack(alignment: .top, spacing: Spacing.xl) {
            RemoteImage(url: viewModel.posterURL, placeholderSymbol: "film")
                .frame(width: 400, height: 600)
                .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerRadius, style: .continuous))
                .shadow(radius: 20)

            VStack(alignment: .leading, spacing: Spacing.m) {
                Text(viewModel.title)
                    .font(AppFonts.title)
                    .lineLimit(2)
                if !viewModel.metadataLine.isEmpty {
                    Text(viewModel.metadataLine)
                        .font(AppFonts.caption)
                        .foregroundStyle(AppColors.textSecondary)
                }
                if let message = viewModel.errorMessage {
                    Text(message).foregroundStyle(AppColors.error)
                }
                if let plot = viewModel.info?.plot, !plot.isEmpty {
                    Text(plot)
                        .lineLimit(5)
                        .foregroundStyle(AppColors.textSecondary)
                }
                if let director = viewModel.info?.director, !director.isEmpty {
                    Text("Director: \(director)").font(AppFonts.caption).foregroundStyle(AppColors.textSecondary)
                }
                if let cast = viewModel.info?.cast, !cast.isEmpty {
                    Text("Cast: \(cast)").font(AppFonts.caption).foregroundStyle(AppColors.textSecondary).lineLimit(2)
                }

                HStack(spacing: Spacing.m) {
                    Button {
                        player.play(viewModel.playableItem)
                    } label: {
                        Label(resumeTitle, systemImage: "play.fill")
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .frame(width: 420)
                    .focused($playFocused)

                    if viewModel.errorMessage != nil {
                        Button("Retry") { Task { await viewModel.load() } }
                            .buttonStyle(SecondaryButtonStyle())
                    }

                    Button {
                        Task { await viewModel.toggleFavorite() }
                    } label: {
                        Label(viewModel.isFavorite ? "In Favorites" : "Add to Favorites", systemImage: viewModel.isFavorite ? "heart.fill" : "heart")
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
                .padding(.top, Spacing.m)
                .focusSection()
            }
            .font(AppFonts.body)
            .foregroundStyle(AppColors.textPrimary)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, Spacing.l)
        .defaultFocus($playFocused, true)
    }

    private var resumeTitle: String {
        guard let position = viewModel.resumePosition else { return "Play" }
        return "Resume from \(Duration.seconds(position).formatted(.time(pattern: position >= 3600 ? .hourMinuteSecond : .minuteSecond)))"
    }
}

#if DEBUG
#Preview {
    let environment = AppEnvironment.preview()
    MovieDetailView(viewModel: MovieDetailViewModel(movie: MockData.movies[0], catalog: MockCatalogRepository(), history: MockWatchHistoryRepository()))
        .environment(environment.playerPresenter)
}
#endif
