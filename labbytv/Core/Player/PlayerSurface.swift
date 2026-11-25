import AVKit
import SwiftUI

/// `AVPlayerViewController` for SwiftUI. SwiftUI's `VideoPlayer` lacks the
/// tvOS transport bar features (info panel, subtitle and audio menus).
struct PlayerSurface: UIViewControllerRepresentable {
    let player: AVPlayer
    let allowsChannelSwitching: Bool
    var isLive = false
    var controlsHandle: PlayerControlsHandle?
    let allowsSpeedChange: Bool
    let aspectMode: VideoAspectMode
    /// Live only: nil hides the favourite button.
    var isFavorite: Bool?
    let onChannelStep: (Int) -> Void
    let onAspectChange: (VideoAspectMode) -> Void
    var onToggleFavorite: () -> Void = {}

    func makeUIViewController(context: Context) -> PlayerContainerController {
        let controller = PlayerContainerController()
        controlsHandle?.controller = controller
        controller.playerController.player = player
        // PiP is Premium on phones, but on Apple TV it isn't built: the player
        // is a full-screen cover that stops playback when it closes, so PiP
        // would show a black screen. Keep it off (it's on by default) so free
        // users don't get a half-working premium feature.
        controller.playerController.allowsPictureInPicturePlayback = false
        return controller
    }

    func updateUIViewController(_ controller: PlayerContainerController, context: Context) {
        let playerController = controller.playerController
        if playerController.player !== player {
            playerController.player = player
        }
        controller.isChannelSwitchingEnabled = allowsChannelSwitching
        // Live: no AVKit Info tab. Swiping down to change channel also
        // opened it (with "From Beginning"), and our channel overlay already
        // shows the programme. Found driving the simulator with XCUIRemote.
        playerController.playbackControlsIncludeInfoViews = !isLive
        controller.onChannelStep = onChannelStep

        playerController.videoGravity = aspectMode.videoGravity
        // The system speed control in the transport bar; an empty list hides
        // it, which live TV needs because it can't play faster than broadcast.
        let speeds = allowsSpeedChange ? PlaybackSpeed.options.map { AVPlaybackSpeed(rate: $0, localizedName: PlaybackSpeed.label(for: $0)) } : []
        if playerController.speeds.map(\.rate) != speeds.map(\.rate) {
            playerController.speeds = speeds
        }
        playerController.transportBarCustomMenuItems = [favoriteAction, aspectMenu].compactMap { $0 }
    }

    /// Same row as Audio/Subtitles, so live TV gets the movie player's
    /// layout (client feedback #4).
    private var favoriteAction: UIAction? {
        guard let isFavorite else { return nil }
        return UIAction(
            title: isFavorite ? "Remove from Favorites" : "Add to Favorites",
            image: UIImage(systemName: isFavorite ? "heart.fill" : "heart")
        ) { _ in
            onToggleFavorite()
        }
    }

    /// Shown above the transport bar next to the built-in Audio/Subtitles menus.
    private var aspectMenu: UIMenu {
        let actions = VideoAspectMode.allCases.map { mode in
            UIAction(title: mode.title, state: mode == aspectMode ? .on : .off) { _ in
                onAspectChange(mode)
            }
        }
        return UIMenu(title: "Aspect Ratio", image: UIImage(systemName: "aspectratio"), children: actions)
    }
}
