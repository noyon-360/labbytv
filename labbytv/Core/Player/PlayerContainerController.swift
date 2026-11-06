import AVKit
import UIKit

/// Hosts `AVPlayerViewController` as a child (Apple says not to subclass it)
/// and adds channel up/down for live TV: swipe or click up/down on the
/// Siri Remote. AVPlayerViewController keeps its own gestures (scrubbing,
/// info panel, subtitle/audio menus); ours recognise alongside them.
final class PlayerContainerController: UIViewController, UIGestureRecognizerDelegate {
    let playerController = AVPlayerViewController()
    var onChannelStep: ((Int) -> Void)?

    var isChannelSwitchingEnabled = false {
        didSet { channelRecognizers.forEach { $0.isEnabled = isChannelSwitchingEnabled } }
    }

    private var channelRecognizers: [UIGestureRecognizer] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black

        addChild(playerController)
        playerController.view.frame = view.bounds
        playerController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(playerController.view)
        playerController.didMove(toParent: self)

        addChannelRecognizer(swipe: .up, press: .upArrow, step: -1)
        addChannelRecognizer(swipe: .down, press: .downArrow, step: 1)
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

    @objc private func channelUp() { onChannelStep?(-1) }
    @objc private func channelDown() { onChannelStep?(1) }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool {
        true
    }
}
