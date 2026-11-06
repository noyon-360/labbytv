import Foundation

/// A request for the PIN pad, shown full screen by `PinPromptPresenter`.
nonisolated struct PinPrompt: Identifiable, Sendable, Equatable {
    enum Kind: Sendable, Equatable {
        /// Check the current PIN. Offers "Forgot PIN?".
        case verify
        /// Choose a new PIN, then enter it again.
        case create
    }

    let id = UUID()
    let kind: Kind
    let subtitle: String?
}

nonisolated enum PinPromptResult: Sendable, Equatable {
    /// The right PIN was entered, or the PIN was removed with the account password.
    case verified
    case created(pin: String)
    case cancelled
}
