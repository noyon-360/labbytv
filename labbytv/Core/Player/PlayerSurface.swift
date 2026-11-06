import AVKit
import SwiftUI

/// `AVPlayerViewController` for SwiftUI. SwiftUI's `VideoPlayer` lacks the
/// tvOS transport bar features (info panel, subtitle and audio menus).
struct PlayerSurface: UIViewControllerRepresentable {
    let player: AVPlayer
    let allowsChannelSwitching: Bool
    let onChannelStep: (Int) -> Void

    func makeUIViewController(context: Context) -> PlayerContainerController {
        let controller = PlayerContainerController()
        controller.playerController.player = player
        return controller
    }

    func updateUIViewController(_ controller: PlayerContainerController, context: Context) {
        if controller.playerController.player !== player {
            controller.playerController.player = player
        }
        controller.isChannelSwitchingEnabled = allowsChannelSwitching
        controller.onChannelStep = onChannelStep
    }
}
