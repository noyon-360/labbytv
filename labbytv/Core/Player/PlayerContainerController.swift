import AVKit
import os
import UIKit

/// Hosts `AVPlayerViewController` as a child (Apple says not to subclass it)
/// and adds channel up/down for live TV: swipe or click up/down on the
/// Siri Remote. AVPlayerViewController keeps its own gestures (scrubbing,
/// info panel, subtitle/audio menus); ours recognise alongside them.
///
/// Up/down only changes channel while the transport bar is hidden. Once the
/// user presses Select and the controls show, up/down belongs to AVKit so it
/// can move focus between the buttons; when the bar hides again, channel
/// up/down comes back.
final class PlayerContainerController: UIViewController, UIGestureRecognizerDelegate, AVPlayerViewControllerDelegate {
    let playerController = AVPlayerViewController()
    var onChannelStep: ((Int) -> Void)?

    var isChannelSwitchingEnabled = false {
        didSet { channelRecognizers.forEach { $0.isEnabled = isChannelSwitchingEnabled } }
    }

    private var channelRecognizers: [UIGestureRecognizer] = []
    private var gate = LiveControlsGate()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black

        playerController.delegate = self
        addChild(playerController)
        playerController.view.frame = view.bounds
        playerController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(playerController.view)
        playerController.didMove(toParent: self)

        addChannelRecognizer(swipe: .up, press: .upArrow, step: -1)
        addChannelRecognizer(swipe: .down, press: .downArrow, step: 1)

        // Select is AVKit's; we only note it, so a bar the user opened on
        // purpose keeps up/down for its buttons.
        let select = UITapGestureRecognizer(target: self, action: #selector(selectPressed))
        select.allowedPressTypes = [NSNumber(value: UIPress.PressType.select.rawValue)]
        select.delegate = self
        select.cancelsTouchesInView = false
        view.addGestureRecognizer(select)
    }

    override var preferredFocusEnvironments: [any UIFocusEnvironment] {
        [playerController]
    }

    private func addChannelRecognizer(swipe direction: UISwipeGestureRecognizer.Direction, press: UIPress.PressType, step: Int) {
        let swipe = UISwipeGestureRecognizer(target: self, action: step < 0 ? #selector(channelUp) : #selector(channelDown))
        swipe.direction = direction
        swipe.delegate = self

        let click = UITapGestureRecognizer(target: self, action: step < 0 ? #selector(channelUp) : #selector(channelDown))
        click.allowedPressTypes = [NSNumber(value: press.rawValue)]
        click.delegate = self

        for recognizer in [swipe, click] {
            recognizer.isEnabled = isChannelSwitchingEnabled
            view.addGestureRecognizer(recognizer)
            channelRecognizers.append(recognizer)
        }
    }

    @objc private func selectPressed() { gate.userPressedSelect() }
    @objc private func channelUp() { step(-1) }
    @objc private func channelDown() { step(1) }

    private func step(_ offset: Int) {
        Logger.player.debug("Remote: channel step \(offset, privacy: .public)")
        gate.channelStepped()
        onChannelStep?(offset)
    }

    /// Back while the transport bar is up hides it instead of closing the
    /// player. Toggling `showsPlaybackControls` is the only public way to
    /// hide AVKit's bar right away; it comes back on the next press.
    func dismissControlsIfVisible() -> Bool {
        guard gate.controlsVisible else { return false }
        playerController.showsPlaybackControls = false
        playerController.showsPlaybackControls = true
        gate.controlsWillChange(visible: false)
        Logger.player.debug("Remote: Back hid the player controls")
        return true
    }

    // MARK: UIGestureRecognizerDelegate

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard channelRecognizers.contains(gestureRecognizer) else { return true }
        let allowed = gate.allowsChannelStep()
        if !allowed {
            Logger.player.debug("Remote: up/down left to the player controls")
        }
        return allowed
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool {
        true
    }

    // MARK: AVPlayerViewControllerDelegate

    func playerViewController(
        _ playerViewController: AVPlayerViewController,
        willTransitionToVisibilityOfTransportBar visible: Bool,
        with coordinator: any AVPlayerViewControllerAnimationCoordinator
    ) {
        gate.controlsWillChange(visible: visible)
        Logger.player.debug("Remote: transport bar \(visible ? "shown" : "hidden", privacy: .public)")

    }
}
