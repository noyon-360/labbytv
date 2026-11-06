import CryptoKit
import Foundation

/// Pure parental-lock rules, kept apart from storage and UI so they can be
/// unit tested. Mirrors Flutter `ParentalLockRules`.
nonisolated enum ParentalLockRules {
    static let pinLength = 4
    static let maxFailures = 5
    static let cooldown: Duration = .seconds(30)

    /// Parental lock is for paid Premium only, not the free trial (same as
    /// Flutter). A parent who already set a PIN keeps access after their plan
    /// ends so they can still change or remove it; the locks keep protecting
    /// the kids either way. Returns nil when the settings may open, otherwise
    /// the message to show.
    static func premiumBlockMessage(hasPin: Bool, isPremium: Bool, isFreeTrial: Bool) -> String? {
        if hasPin || (isPremium && !isFreeTrial) { return nil }
        if isFreeTrial {
            return "Parental lock is for paid subscribers and isn't part of the free trial. It unlocks automatically when your plan starts."
        }
        return "Parental lock is a Premium feature for paid subscribers (not included in the free trial)."
    }

    static func isValidPin(_ pin: String) -> Bool {
        pin.count == pinLength && pin.allSatisfy { $0.isASCII && $0.isNumber }
    }

    /// Same format as Flutter: SHA-256 of `"salt:pin"` as lowercase hex.
    static func hashPin(_ pin: String, salt: String) -> String {
        SHA256.hash(data: Data("\(salt):\(pin)".utf8))
            .map { String(format: "%02x", $0) }
            .joined()
    }

    /// 16 random bytes, base64url, like Flutter's `newSalt`.
    /// `SystemRandomNumberGenerator` is cryptographically secure on Apple platforms.
    static func newSalt() -> String {
        let bytes = (0..<16).map { _ in UInt8.random(in: .min ... .max) }
        return Data(bytes).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
    }

    /// Locks only count while a PIN exists: without one nobody could unlock
    /// them. "All" (empty id) is never locked itself; its locked items are
    /// filtered out instead. `unlockedIDs` are the locked categories the PIN
    /// was entered for this session.
    static func isHidden(hasPin: Bool, lockedIDs: Set<String>, unlockedIDs: Set<String>, categoryID: String) -> Bool {
        hasPin
            && !categoryID.isEmpty
            && lockedIDs.contains(categoryID)
            && !unlockedIDs.contains(categoryID)
    }
}
