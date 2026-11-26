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
    /// Parental lock PIN (salted SHA-256, never the PIN itself). Survives
    /// sign-out, as in the Flutter app: the lock belongs to the device.
    case parentalPinHash
    case parentalPinSalt
    /// The "Who's Watching" profile this device uses, sent as `X-Profile-ID`.
    /// Not secret, but it lives with the session so sign-out clears it.
    case viewerProfileId

    /// Everything cleared on sign-out.
    static let sessionKeys: [SecureStoreKey] = [.accessToken, .refreshToken, .userId, .role, .activePlaylist, .viewerProfileId]
}
