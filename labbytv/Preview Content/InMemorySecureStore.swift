#if DEBUG
import Foundation
import os

/// `SecureStore` for previews and tests. Never touches the Keychain.
nonisolated final class InMemorySecureStore: SecureStore {
    private let values: OSAllocatedUnfairLock<[SecureStoreKey: String]>

    init(_ initial: [SecureStoreKey: String] = [:]) {
        values = OSAllocatedUnfairLock(initialState: initial)
    }

    func string(for key: SecureStoreKey) -> String? {
        values.withLock { $0[key] }
    }

    func set(_ value: String, for key: SecureStoreKey) {
        values.withLock { $0[key] = value }
    }

    func remove(_ key: SecureStoreKey) {
        values.withLock { _ = $0.removeValue(forKey: key) }
    }
}
#endif
