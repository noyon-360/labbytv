import Foundation

/// The subset of Flutter `UserModel` the TV app uses. The backend sends the
/// whole user document (including the password hash), so decode only what we
/// need and never log the raw response.
nonisolated struct User: Decodable, Sendable, Equatable {
    let id: String?
    let name: String?
    let email: String?
    let role: String?
    let plan: String?
    let subscriptionStatus: String?
    let isEmailVerified: Bool?
    /// ISO-8601 string; parsed by `hasActiveSubscription`.
    let subscriptionExpiresAt: String?

    private enum CodingKeys: String, CodingKey {
        case name, email, role, plan, subscriptionStatus, isEmailVerified, subscriptionExpiresAt
        case id = "_id"
    }

    /// Same rule as Flutter `UserModel.hasActiveSubscription`: status says
    /// active/trialing AND the paid period hasn't ended. The backend's expiry
    /// job runs once a day, so the status alone can be stale for hours.
    func hasActiveSubscription(now: Date = .now) -> Bool {
        guard subscriptionStatus == "active" || subscriptionStatus == "trialing" else { return false }
        guard let subscriptionExpiresAt, let expiry = Self.parseDate(subscriptionExpiresAt) else { return true }
        return expiry > now
    }

    /// In a store free trial: the backend sets "trialing" from RevenueCat's
    /// period_type and switches to "active" once the first payment goes through.
    func isOnFreeTrial(now: Date = .now) -> Bool {
        subscriptionStatus == "trialing" && hasActiveSubscription(now: now)
    }

    var expiresAt: Date? { subscriptionExpiresAt.flatMap(Self.parseDate) }

    static func parseDate(_ string: String) -> Date? {
        let withFraction = ISO8601DateFormatter()
        withFraction.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = withFraction.date(from: string) { return date }
        return ISO8601DateFormatter().date(from: string)
    }
}
