import Foundation

nonisolated enum SecureStoreKey: String, CaseIterable, Sendable {
    case accessToken
    case refreshToken
    case userId
    case role
    /// JSON of the chosen `Playlist`. It holds the IPTV password, so it
    /// lives in the Keychain, not UserDefaults.
    case activePlaylist
    /// Survives sign-out: the backend keeps one session per device.
    case deviceId

    /// Everything cleared on sign-out.
    static let sessionKeys: [SecureStoreKey] = [.accessToken, .refreshToken, .userId, .role, .activePlaylist]
}
