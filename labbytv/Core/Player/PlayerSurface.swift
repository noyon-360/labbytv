import AVKit
import SwiftUI

/// `AVPlayerViewController` for SwiftUI. SwiftUI's `VideoPlayer` lacks the
/// tvOS transport bar features (info panel, subtitle and audio menus).
struct PlayerSurface: UIViewControllerRepresentable {
    let player: AVPlayer
    let allowsChannelSwitching: Bool
    let allowsSpeedChange: Bool
    let aspectMode: VideoAspectMode
    let onChannelStep: (Int) -> Void
    let onAspectChange: (VideoAspectMode) -> Void

    func makeUIViewController(context: Context) -> PlayerContainerController {
        let controller = PlayerContainerController()
        controller.playerController.player = player
        return controller
    }

    func updateUIViewController(_ controller: PlayerContainerController, context: Context) {
        let playerController = controller.playerController
        if playerController.player !== player {
            playerController.player = player
        }
        controller.isChannelSwitchingEnabled = allowsChannelSwitching
        controller.onChannelStep = onChannelStep

        playerController.videoGravity = aspectMode.videoGravity
        // The system speed control in the transport bar; an empty list hides
        // it, which live TV needs because it can't play faster than broadcast.
        let speeds = allowsSpeedChange ? PlaybackSpeed.options.map { AVPlaybackSpeed(rate: $0, localizedName: PlaybackSpeed.label(for: $0)) } : []
        if playerController.speeds.map(\.rate) != speeds.map(\.rate) {
            playerController.speeds = speeds
        }
        playerController.transportBarCustomMenuItems = [aspectMenu]
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
