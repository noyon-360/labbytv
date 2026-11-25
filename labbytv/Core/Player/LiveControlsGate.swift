import Foundation

/// Decides whether an up/down press on the live player changes channel or
/// belongs to the player controls. When the user opens the controls with
/// Select, up/down must move between the buttons (Audio, Subtitles,
/// Aspect…); the client couldn't reach them because every press also
/// changed channel. But AVKit also shows its bar for the very press that
/// changes channel, and that bar must not stop the next channel change.
nonisolated struct LiveControlsGate: Sendable {
    /// When the transport bar appeared; nil while it's hidden.
    private(set) var controlsShownAt: Date?
    /// The bar is up only because the user is changing channels.
    private(set) var openedBySurfing = false
    private var lastChannelStep: Date?

    /// AVKit shows its bar in response to the same press we read as channel
    /// up/down, a moment before or after our recogniser fires.
    static let gestureGrace: TimeInterval = 0.35

    var controlsVisible: Bool { controlsShownAt != nil }

    mutating func controlsWillChange(visible: Bool, at date: Date = .now) {
        if visible {
            guard controlsShownAt == nil else { return }
            controlsShownAt = date
            openedBySurfing = lastChannelStep.map { abs(date.timeIntervalSince($0)) < Self.gestureGrace } ?? false
        } else {
            controlsShownAt = nil
            openedBySurfing = false
        }
    }

    mutating func channelStepped(at date: Date = .now) {
        lastChannelStep = date
        if let controlsShownAt, date.timeIntervalSince(controlsShownAt) < Self.gestureGrace {
            openedBySurfing = true
        }
    }

    /// Select means the user wants the controls: up/down now belong to them.
    mutating func userPressedSelect() {
        openedBySurfing = false
    }

    func allowsChannelStep(at date: Date = .now) -> Bool {
        guard let shownAt = controlsShownAt else { return true }
        return openedBySurfing || date.timeIntervalSince(shownAt) < Self.gestureGrace
    }
}
