import Foundation

/// Lets the SwiftUI player ask the AVKit container whether Back should only
/// hide the controls. SwiftUI's exit command fires before AVKit gets the
/// press, so without this Back closed the player while the controls were
/// open (client feedback #15; seen driving the simulator with XCUIRemote).
@MainActor
final class PlayerControlsHandle {
    weak var controller: PlayerContainerController?

    /// True if the controls were open and are now hidden.
    func dismissControlsIfVisible() -> Bool {
        controller?.dismissControlsIfVisible() ?? false
    }
}
