import Foundation

/// A subscription's billing period, read from the App Store product itself.
/// The RevenueCat package type is set by hand in the RevenueCat dashboard and
/// can disagree with the product (the quarterly plan showed "every 6 months").
nonisolated struct BillingPeriod: Hashable, Sendable {
    let unit: FreeTrialOffer.Unit
    let value: Int

    /// For sorting plans shortest first, like the phone app.
    var approximateDays: Int { FreeTrialOffer(unit: unit, count: value).days }

    /// "per month", "every 3 months", "per year".
    var text: String {
        let word = switch unit {
        case .day: "day"
        case .week: "week"
        case .month: "month"
        case .year: "year"
        }
        return value == 1 ? "per \(word)" : "every \(value) \(word)s"
    }
}
