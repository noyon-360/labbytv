import Foundation

/// Result of checking an entered PIN.
nonisolated enum PinCheck: Sendable, Equatable {
    case ok
    case wrong
    /// Too many wrong tries; wait for the cooldown.
    case blocked
}
