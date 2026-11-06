import Foundation

/// The active playlist's Xtream login. Sent to the backend, which proxies
/// the provider; the app never calls the IPTV server for catalog data.
/// Contains a password: keep it in the Keychain and never log it.
nonisolated struct ServerCredentials: Codable, Sendable, Equatable {
    let serverUrl: String
    let username: String
    let password: String
}
