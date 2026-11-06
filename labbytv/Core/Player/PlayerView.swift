import SwiftUI

/// Full-screen playback. Menu/Back closes it (AVPlayerViewController hides
/// its own UI first, then the cover dismisses).
struct PlayerView: View {
    @State private var viewModel: PlayerViewModel
    let showsWatermark: Bool
    let onClose: () -> Void

    init(viewModel: PlayerViewModel, showsWatermark: Bool, onClose: @escaping () -> Void) {
        _viewModel = State(initialValue: viewModel)
        self.showsWatermark = showsWatermark
        self.onClose = onClose
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            PlayerSurface(
                player: viewModel.player,
                allowsChannelSwitching: viewModel.canSwitchChannels,
                onChannelStep: { step in Task { await viewModel.switchChannel(by: step) } }
            )
            .ignoresSafeArea()

            switch viewModel.state {
            case .loading:
                LoadingView(message: viewModel.item.title)
                    .allowsHitTesting(false)
            case .failed(let message):
                ErrorView(message: message, retry: { Task { await viewModel.retry() } }, secondaryTitle: "Close", secondaryAction: onClose)
                    .background(Color.black.opacity(0.85).ignoresSafeArea())
            case .playing:
                EmptyView()
            }

            overlays
        }
        .task { await viewModel.start() }
        .onDisappear { Task { await viewModel.stop() } }
        .onExitCommand(perform: onClose)
    }

    private var overlays: some View {
        VStack {
            HStack {
                if let channel = viewModel.channelBanner {
                    ChannelBanner(channel: channel)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
                Spacer()
            }
            Spacer()
            HStack {
                Spacer()
                // Free plan: the LABBY logo watermark, removed by LABBY TV Pro.
                if showsWatermark {
                    Image(.logo)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 90, height: 90)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                        .opacity(0.55)
                        .accessibilityHidden(true)
                }
            }
        }
        .padding(Spacing.xl)
        .allowsHitTesting(false)
        .animation(.easeInOut, value: viewModel.channelBanner)
    }
}

private struct ChannelBanner: View {
    let channel: Channel

    var body: some View {
        HStack(spacing: Spacing.m) {
            RemoteImage(url: channel.imageURL, contentMode: .fit)
                .frame(width: 120, height: 68)
            VStack(alignment: .leading) {
                if channel.num > 0 {
                    Text("CH \(channel.num)")
                        .font(AppFonts.caption)
                        .foregroundStyle(AppColors.textSecondary)
                }
                Text(channel.name)
                    .font(AppFonts.headline)
                    .foregroundStyle(AppColors.textPrimary)
            }
        }
        .padding(Spacing.m)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: Spacing.cornerRadius))
    }
}
