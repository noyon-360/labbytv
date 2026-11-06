import Foundation
import Observation
import os
#if canImport(RevenueCat)
import RevenueCat
#endif

/// The `LABBY TV Pro` entitlement. Premium if RevenueCat says so, or if the
/// backend user record has an active subscription (bought on Android or
/// before RevenueCat; the backend's webhook keeps that in sync).
@MainActor
@Observable
final class PremiumService {
    static let entitlementID = "LABBY TV Pro"

    private(set) var hasEntitlement = false
    private(set) var backendSubscriptionActive = false
    private(set) var packages: [PremiumPackage] = []

    var isPremium: Bool { hasEntitlement || backendSubscriptionActive }

    /// Store side (instant after purchase) and backend side (bought on another
    /// device). Either can say the current period is a free trial.
    private(set) var entitlementInTrial = false
    private(set) var backendInTrial = false
    private(set) var entitlementExpiresAt: Date?
    private(set) var backendExpiresAt: Date?

    var isInFreeTrial: Bool { isPremium && (entitlementInTrial || backendInTrial) }

    /// When the trial (or current period) ends, for "Trial ends 14 Nov".
    var currentPeriodEndsAt: Date? { entitlementExpiresAt ?? backendExpiresAt }

    /// A free trial this user can still start on some plan.
    var availableFreeTrial: FreeTrialOffer? { packages.lazy.compactMap(\.trial).first }

    /// False until the RevenueCat package and API key are set up.
    private(set) var isPurchasingAvailable = false

    #if canImport(RevenueCat)
    @ObservationIgnored private var rcPackages: [String: Package] = [:]
    #endif

    /// Reads `RevenueCatAPIKey` from Info.plist (set from `Config/Secrets.xcconfig`).
    func configure() {
        #if canImport(RevenueCat)
        guard let key = Bundle.main.object(forInfoDictionaryKey: "RevenueCatAPIKey") as? String,
              !key.isEmpty, !key.hasPrefix("$(") else {
            Logger.premium.error("RevenueCatAPIKey missing from Info.plist; purchases disabled")
            return
        }
        Purchases.configure(withAPIKey: key)
        isPurchasingAvailable = true
        Task { await listenForCustomerInfo() }
        #else
        Logger.premium.notice("RevenueCat package not linked; purchases disabled")
        #endif
    }

    /// Ties purchases to our user id so the backend webhook can match them.
    func logIn(userID: String) async {
        #if canImport(RevenueCat)
        guard isPurchasingAvailable else { return }
        do {
            let result = try await Purchases.shared.logIn(userID)
            apply(result.customerInfo)
        } catch {
            Logger.premium.error("RevenueCat logIn failed: \(error.localizedDescription, privacy: .public)")
        }
        #endif
    }

    func logOut() async {
        hasEntitlement = false
        backendSubscriptionActive = false
        entitlementInTrial = false
        backendInTrial = false
        entitlementExpiresAt = nil
        backendExpiresAt = nil
        #if canImport(RevenueCat)
        guard isPurchasingAvailable, !Purchases.shared.isAnonymous else { return }
        _ = try? await Purchases.shared.logOut()
        #endif
    }

    func update(from user: User?) {
        guard let user else { return }
        // Same rule as Flutter `PremiumService._fromBackend`: plan AND a live
        // period. `plan` alone stays "premium" for up to a day after expiry
        // (the backend downgrades in a daily job), so it can't stand alone.
        backendSubscriptionActive = user.plan == "premium" && user.hasActiveSubscription()
        backendInTrial = user.isOnFreeTrial()
        backendExpiresAt = user.expiresAt
    }

    func loadPackages() async throws {
        #if canImport(RevenueCat)
        guard isPurchasingAvailable else { return }
        let offerings = try await Purchases.shared.offerings()
        let available = offerings.current?.availablePackages ?? []
        rcPackages = Dictionary(available.map { ($0.identifier, $0) }, uniquingKeysWith: { first, _ in first })
        // The product always carries its intro offer, even for users who
        // already used a trial, so ask StoreKit who is eligible before
        // advertising it. Unknown counts as not eligible.
        let eligibility = await Purchases.shared.checkTrialOrIntroDiscountEligibility(packages: available)
        // Shortest plan first (monthly, quarterly, yearly), as on the phone.
        let sorted = available.sorted {
            (Self.billingPeriod($0)?.approximateDays ?? .max) < (Self.billingPeriod($1)?.approximateDays ?? .max)
        }
        packages = sorted.map { package in
            PremiumPackage(
                id: package.identifier,
                title: package.storeProduct.localizedTitle,
                price: package.storeProduct.localizedPriceString,
                period: Self.billingPeriod(package)?.text ?? Self.periodText(package.packageType),
                trial: eligibility[package]?.status == .eligible
                    ? Self.freeTrial(package.storeProduct.introductoryDiscount)
                    : nil
            )
        }
        #endif
    }

    /// Returns false if the user cancelled.
    func purchase(_ package: PremiumPackage) async throws -> Bool {
        #if canImport(RevenueCat)
        guard let rcPackage = rcPackages[package.id] else { return false }
        let result = try await Purchases.shared.purchase(package: rcPackage)
        apply(result.customerInfo)
        return !result.userCancelled
        #else
        return false
        #endif
    }

    func restore() async throws {
        #if canImport(RevenueCat)
        guard isPurchasingAvailable else { return }
        let info = try await Purchases.shared.restorePurchases()
        apply(info)
        #endif
    }

    #if canImport(RevenueCat)
    private func listenForCustomerInfo() async {
        for await info in Purchases.shared.customerInfoStream {
            apply(info)
        }
    }

    private func apply(_ info: CustomerInfo) {
        let entitlement = info.entitlements[Self.entitlementID]
        hasEntitlement = entitlement?.isActive == true
        entitlementInTrial = hasEntitlement && entitlement?.periodType == .trial
        entitlementExpiresAt = hasEntitlement ? entitlement?.expirationDate : nil
    }

    private static func freeTrial(_ discount: StoreProductDiscount?) -> FreeTrialOffer? {
        guard let discount, discount.paymentMode == .freeTrial,
              let unit = unit(discount.subscriptionPeriod.unit) else { return nil }
        return FreeTrialOffer(unit: unit, count: discount.subscriptionPeriod.value * max(discount.numberOfPeriods, 1))
    }

    private static func billingPeriod(_ package: Package) -> BillingPeriod? {
        guard let period = package.storeProduct.subscriptionPeriod, let unit = unit(period.unit) else { return nil }
        return BillingPeriod(unit: unit, value: period.value)
    }

    private static func unit(_ unit: SubscriptionPeriod.Unit) -> FreeTrialOffer.Unit? {
        switch unit {
        case .day: .day
        case .week: .week
        case .month: .month
        case .year: .year
        @unknown default: nil
        }
    }

    private static func periodText(_ type: PackageType) -> String {
        switch type {
        case .monthly: "per month"
        case .threeMonth: "every 3 months"
        case .sixMonth: "every 6 months"
        case .annual: "per year"
        case .weekly: "per week"
        case .lifetime: "one time"
        default: ""
        }
    }
    #endif
}
