import Foundation

/// Secret storage. `KeychainStore` in the app; an in-memory store in tests and previews.
nonisolated protocol SecureStore: Sendable {
    func string(for key: SecureStoreKey) -> String?
    func set(_ value: String, for key: SecureStoreKey)
    func remove(_ key: SecureStoreKey)
}

nonisolated extension SecureStore {
    func clearSession() {
        SecureStoreKey.sessionKeys.forEach(remove)
    }

    /// Same format as the Flutter app: 16 random bytes as lowercase hex.
    /// `SystemRandomNumberGenerator` is cryptographically secure on Apple platforms.
    func deviceID() -> String {
        if let existing = string(for: .deviceId), !existing.isEmpty {
            return existing
        }
        let id = (0..<16)
            .map { _ in String(format: "%02x", UInt8.random(in: .min ... .max)) }
            .joined()
        set(id, for: .deviceId)
        return id
    }
}
