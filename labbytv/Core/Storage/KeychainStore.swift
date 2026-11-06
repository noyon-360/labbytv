import Foundation
import os
import Security

/// Generic-password Keychain items, one per `SecureStoreKey`.
/// SecItem calls are thread-safe, so this type has no isolation.
nonisolated final class KeychainStore: SecureStore {
    private let service: String

    init(service: String = Bundle.main.bundleIdentifier ?? "com.almightyflippa.labbytv") {
        self.service = service
    }

    func string(for key: SecureStoreKey) -> String? {
        var query = baseQuery(for: key)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess, let data = item as? Data else {
            if status != errSecItemNotFound {
                Logger.storage.error("Keychain read failed for \(key.rawValue, privacy: .public): \(status)")
            }
            return nil
        }
        return String(decoding: data, as: UTF8.self)
    }

    func set(_ value: String, for key: SecureStoreKey) {
        let data = Data(value.utf8)
        let query = baseQuery(for: key)
        let updateStatus = SecItemUpdate(query as CFDictionary, [kSecValueData as String: data] as CFDictionary)

        if updateStatus == errSecItemNotFound {
            var attributes = query
            attributes[kSecValueData as String] = data
            // ThisDeviceOnly: tokens are bound to this device's session on the backend.
            attributes[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
            let addStatus = SecItemAdd(attributes as CFDictionary, nil)
            if addStatus != errSecSuccess {
                Logger.storage.error("Keychain add failed for \(key.rawValue, privacy: .public): \(addStatus)")
            }
        } else if updateStatus != errSecSuccess {
            Logger.storage.error("Keychain update failed for \(key.rawValue, privacy: .public): \(updateStatus)")
        }
    }

    func remove(_ key: SecureStoreKey) {
        let status = SecItemDelete(baseQuery(for: key) as CFDictionary)
        if status != errSecSuccess && status != errSecItemNotFound {
            Logger.storage.error("Keychain delete failed for \(key.rawValue, privacy: .public): \(status)")
        }
    }

    private func baseQuery(for key: SecureStoreKey) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key.rawValue,
        ]
    }
}
