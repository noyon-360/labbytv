import Foundation

/// Which guide cell has focus; drives the details panel above the grid.
nonisolated enum GuideFocus: Hashable, Sendable {
    case channel(Int)
    case program(channelID: Int, programID: String)
}
