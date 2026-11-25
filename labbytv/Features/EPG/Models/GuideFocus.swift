import Foundation

/// Which guide cell has focus; drives the details panel above the grid.
nonisolated enum GuideFocus: Hashable, Sendable {
    case channel(Int)
    case program(channelID: Int, programID: String)
    /// Invisible strip after a row's last programme. Focus only lands here
    /// when the user moves right past the visible window, which slides the
    /// guide forward (client: scroll the timeline with the remote).
    case later(channelID: Int)

    var channelID: Int {
        switch self {
        case .channel(let id), .later(let id): id
        case .program(let id, _): id
        }
    }
}
