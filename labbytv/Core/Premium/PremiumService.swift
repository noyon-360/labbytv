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
        #if canImport(RevenueCat)
        guard isPurchasingAvailable, !Purchases.shared.isAnonymous else { return }
        _ = try? await Purchases.shared.logOut()
        #endif
    }

    func update(from user: User?) {
        guard let user else { return }
        backendSubscriptionActive = user.hasActiveSubscription() || user.plan == "premium"
    }

    func loadPackages() async throws {
        #if canImport(RevenueCat)
        guard isPurchasingAvailable else { return }
        let offerings = try await Purchases.shared.offerings()
        let available = offerings.current?.availablePackages ?? []
        rcPackages = Dictionary(available.map { ($0.identifier, $0) }, uniquingKeysWith: { first, _ in first })
        packages = available.map { package in
            PremiumPackage(
                id: package.identifier,
                title: package.storeProduct.localizedTitle,
                price: package.storeProduct.localizedPriceString,
                period: Self.periodText(package.packageType)
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
        hasEntitlement = info.entitlements[Self.entitlementID]?.isActive == true
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
