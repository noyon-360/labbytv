import SwiftUI

struct LiveTVView: View {
    @Environment(PlayerPresenter.self) private var player
    @Environment(ChannelFavorites.self) private var favorites
    let viewModel: CatalogViewModel<Channel>

    var body: some View {
        CatalogGridView(viewModel: viewModel, columns: 5, emptySymbol: "tv") { channel in
            ChannelCard(channel: channel, isFavorite: favorites.isFavorite(channel.id)) {
                // The lineup is the current category, so channel up/down
                // in the player stays inside it (as in the Flutter app).
                player.play(.live(channel, lineup: viewModel.items))
            }
            // Press and hold Select on a channel.
            .contextMenu {
                Button {
                    Task { await favorites.toggle(channel) }
                } label: {
                    if favorites.isFavorite(channel.id) {
                        Label("Remove from Favorites", systemImage: "heart.slash")
                    } else {
                        Label("Add to Favorites", systemImage: "heart")
                    }
                }
            }
        }
        .task { await favorites.loadIfNeeded() }
    }
}

#if DEBUG
#Preview {
    let environment = AppEnvironment.preview()
    LiveTVView(viewModel: CatalogViewModel(type: .channels, repository: MockCatalogRepository()))
        .environment(environment.playerPresenter)
        .environment(environment.channelFavorites)
}
#endif
