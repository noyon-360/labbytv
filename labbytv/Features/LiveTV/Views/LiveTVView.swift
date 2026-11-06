import SwiftUI

struct LiveTVView: View {
    @Environment(PlayerPresenter.self) private var player
    let viewModel: CatalogViewModel<Channel>

    var body: some View {
        CatalogGridView(viewModel: viewModel, columns: 5, emptySymbol: "tv") { channel in
            ChannelCard(channel: channel) {
                // The lineup is the current category, so channel up/down
                // in the player stays inside it (as in the Flutter app).
                player.play(.live(channel, lineup: viewModel.items))
            }
        }
    }
}

#if DEBUG
#Preview {
    let environment = AppEnvironment.preview()
    LiveTVView(viewModel: CatalogViewModel(type: .channels, repository: MockCatalogRepository()))
        .environment(environment.playerPresenter)
}
#endif
