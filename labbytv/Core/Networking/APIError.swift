import Foundation

nonisolated enum APIError: Error, Equatable, Sendable {
    /// The device is offline or the host can't be reached.
    case noConnection
    case timeout
    /// The backend answered with `success: false` or a non-2xx status.
    case server(status: Int, message: String)
    /// The session ended (refresh token rejected); the user must sign in again.
    case unauthorized
    /// The response didn't match the expected model.
    case decoding
    /// A content call ran before a playlist was chosen.
    case noPlaylist
    case unknown

    var userMessage: String {
        switch self {
        case .noConnection:
            return "No internet connection. Check your network and try again."
        case .timeout:
            return "The server took too long to respond. Please try again."
        case .server(let status, let message):
            if !message.isEmpty { return message }
            return Self.fallbackMessage(for: status)
        case .unauthorized:
            return "Your session has expired. Please sign in again."
        case .decoding:
            return "We received an unexpected response. Please try again."
        case .noPlaylist:
            return "Choose a playlist first."
        case .unknown:
            return "Something went wrong. Please try again."
        }
    }

    private static func fallbackMessage(for status: Int) -> String {
        switch status {
        case 400: return "Bad request. Please check your input."
        case 401: return "Unauthorized. Please sign in again."
        case 403: return "You don't have permission to do that."
        case 404: return "Not found."
        case 429: return "Too many requests. Please wait a moment."
        case 500...599: return "Server error. Please try again later."
        default: return "Something went wrong. Please try again."
        }
    }
}
