import Foundation

/// A purchasable plan, copied out of RevenueCat so views don't depend on it.
nonisolated struct PremiumPackage: Identifiable, Hashable, Sendable {
    let id: String
    let title: String
    let price: String
    let period: String
    /// The free trial this user can still get on the plan; nil if there is
    /// none or they already used it.
    var trial: FreeTrialOffer? = nil
}
