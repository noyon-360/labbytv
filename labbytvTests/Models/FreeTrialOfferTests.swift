import Foundation
import Testing
@testable import labbytv

struct FreeTrialOfferTests {
    @Test func sevenDayCopy() {
        let trial = FreeTrialOffer(unit: .day, count: 7)
        #expect(trial.label == "7-day free trial")
        #expect(trial.buttonLabel == "Start 7-Day Free Trial")
        #expect(trial.durationText == "7 days")
    }

    @Test func oneWeekReadsAsSevenDays() {
        let trial = FreeTrialOffer(unit: .week, count: 1)
        #expect(trial.days == 7)
        #expect(trial.label == "7-day free trial")
    }

    @Test func monthCopy() {
        let trial = FreeTrialOffer(unit: .month, count: 1)
        #expect(trial.durationText == "1 month")
        #expect(trial.buttonLabel == "Start 1-Month Free Trial")
    }

    @Test func termsStateLengthPriceAndHowToAvoidCharge() {
        let trial = FreeTrialOffer(unit: .day, count: 7)
        #expect(trial.termsText(priceAndPeriod: "$4.99 per month")
            == "Free for 7 days, then $4.99 per month. Cancel anytime before the trial ends and you won't be charged.")
    }

    private func user(status: String, expires: Date) throws -> User {
        let iso = ISO8601DateFormatter().string(from: expires)
        let json = #"{"_id":"1","plan":"premium","subscriptionStatus":"\#(status)","subscriptionExpiresAt":"\#(iso)"}"#
        return try JSONDecoder().decode(User.self, from: Data(json.utf8))
    }

    @Test func backendTrialingIsAFreeTrial() throws {
        let trialing = try user(status: "trialing", expires: .now.addingTimeInterval(5 * 86_400))
        #expect(trialing.hasActiveSubscription())
        #expect(trialing.isOnFreeTrial())
        #expect(trialing.expiresAt != nil)
    }

    @Test func paidOrEndedIsNotATrial() throws {
        #expect(try !user(status: "active", expires: .now.addingTimeInterval(86_400)).isOnFreeTrial())
        #expect(try !user(status: "trialing", expires: .now.addingTimeInterval(-3_600)).isOnFreeTrial())
    }
}

@MainActor
struct PremiumServiceBackendTests {
    private func user(plan: String, status: String, expires: Date) throws -> User {
        let iso = ISO8601DateFormatter().string(from: expires)
        let json = #"{"_id":"1","plan":"\#(plan)","subscriptionStatus":"\#(status)","subscriptionExpiresAt":"\#(iso)"}"#
        return try JSONDecoder().decode(User.self, from: Data(json.utf8))
    }

    @Test func expiredButNotYetDowngradedIsNotPremium() throws {
        // The backend's daily job hasn't reset plan/status yet.
        let premium = PremiumService()
        premium.update(from: try user(plan: "premium", status: "active", expires: .now.addingTimeInterval(-3_600)))
        #expect(!premium.isPremium)
    }

    @Test func trialUserIsPremiumAndInTrial() throws {
        let premium = PremiumService()
        premium.update(from: try user(plan: "premium", status: "trialing", expires: .now.addingTimeInterval(5 * 86_400)))
        #expect(premium.isPremium)
        #expect(premium.isInFreeTrial)
    }
}

struct BillingPeriodTests {
    @Test func textFromTheProductPeriod() {
        #expect(BillingPeriod(unit: .month, value: 1).text == "per month")
        #expect(BillingPeriod(unit: .month, value: 3).text == "every 3 months")
        #expect(BillingPeriod(unit: .year, value: 1).text == "per year")
    }

    @Test func sortsShortestFirst() {
        let plans = [BillingPeriod(unit: .year, value: 1), BillingPeriod(unit: .month, value: 3), BillingPeriod(unit: .month, value: 1)]
        #expect(plans.sorted { $0.approximateDays < $1.approximateDays }.map(\.text) == ["per month", "every 3 months", "per year"])
    }
}
