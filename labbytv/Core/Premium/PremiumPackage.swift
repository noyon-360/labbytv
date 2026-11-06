import Foundation

/// A purchasable plan, copied out of RevenueCat so views don't depend on it.
nonisolated struct PremiumPackage: Identifiable, Hashable, Sendable {
    let id: String
    let title: String
    let price: String
    let period: String
}
