import Foundation

/// A store free trial (App Store introductory offer) on a subscription.
/// The trial is configured in App Store Connect; this only describes it so the
/// paywall can say so before the user buys. Copy matches the Flutter app.
nonisolated struct FreeTrialOffer: Hashable, Sendable {
    enum Unit: Sendable { case day, week, month, year }

    let unit: Unit
    let count: Int

    var days: Int {
        switch unit {
        case .day: count
        case .week: count * 7
        case .month: count * 30
        case .year: count * 365
        }
    }

    /// "7-day", "1-month". Weeks read as days, the way users describe them.
    var lengthLabel: String {
        switch unit {
        case .day, .week: "\(days)-day"
        case .month: "\(count)-month"
        case .year: "\(count)-year"
        }
    }

    /// "7-day free trial"
    var label: String { "\(lengthLabel) free trial" }

    /// "Start 7-Day Free Trial"
    var buttonLabel: String {
        let parts = lengthLabel.split(separator: "-")
        return "Start \(parts[0])-\(parts[1].capitalized) Free Trial"
    }

    /// "7 days", "1 month"
    var durationText: String {
        func plural(_ n: Int, _ word: String) -> String { "\(n) \(word)\(n == 1 ? "" : "s")" }
        switch unit {
        case .day, .week: return plural(days, "day")
        case .month: return plural(count, "month")
        case .year: return plural(count, "year")
        }
    }

    /// The terms Apple requires next to a trial: length, the price after it,
    /// and how to avoid being charged. `priceAndPeriod` e.g. "$4.99 per month".
    func termsText(priceAndPeriod: String) -> String {
        "Free for \(durationText), then \(priceAndPeriod). Cancel anytime before the trial ends and you won't be charged."
    }
}
