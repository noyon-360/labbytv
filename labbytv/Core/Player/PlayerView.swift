import SwiftUI

/// Full-screen playback. Menu/Back closes it (AVPlayerViewController hides
/// its own UI first, then the cover dismisses).
struct PlayerView: View {
    @State private var viewModel: PlayerViewModel
    @State private var controlsHandle = PlayerControlsHandle()
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

            surface

            switch viewModel.state {
            case .loading:
                if !viewModel.hasStream {
                    LoadingView(message: viewModel.item.title)
                        .allowsHitTesting(false)
                }
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
        // First Back hides AVKit's controls, the next one closes. (VLC
        // handles Back itself in VLCPlayerView.)
        .onExitCommand {
            if viewModel.backend == .avPlayer && controlsHandle.dismissControlsIfVisible() { return }
            onClose()
        }
        .onChange(of: viewModel.didFinish) {
            if viewModel.didFinish { onClose() }
        }
    }

    @ViewBuilder
    private var surface: some View {
        #if canImport(LabbyVLC)
        if viewModel.backend == .vlc, let engine = viewModel.vlc {
            // VLCPlayerView handles Menu itself (hide controls, then close).
            VLCPlayerView(
                engine: engine,
                title: viewModel.item.title,
                aspectMode: viewModel.aspectMode,
                speed: viewModel.speed,
                onAspectChange: viewModel.setAspectMode,
                onSpeedChange: viewModel.setSpeed,
                onClose: onClose
            )
        } else {
            avSurface
        }
        #else
        avSurface
        #endif
    }

    private var avSurface: some View {
        PlayerSurface(
            player: viewModel.player,
            allowsChannelSwitching: viewModel.canSwitchChannels,
            isLive: viewModel.item.isLive,
            controlsHandle: controlsHandle,
            allowsSpeedChange: viewModel.canChangeSpeed,
            aspectMode: viewModel.aspectMode,
            isFavorite: viewModel.canFavorite ? viewModel.isFavoriteChannel : nil,
            onChannelStep: { step in Task { await viewModel.switchChannel(by: step) } },
            onAspectChange: viewModel.setAspectMode,
            onToggleFavorite: { Task { await viewModel.toggleFavorite() } }
        )
        .ignoresSafeArea()
    }

    private var overlays: some View {
        ZStack(alignment: .bottom) {
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
            .frame(maxHeight: .infinity, alignment: .bottom)

            if let channel = viewModel.channelBanner {
                ChannelInfoOverlay(channel: channel, nowNext: viewModel.nowNext, isFavorite: viewModel.isFavoriteChannel)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .padding(Spacing.xl)
        .allowsHitTesting(false)
        .animation(.easeInOut, value: viewModel.channelBanner)
    }
}
