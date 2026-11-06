import Foundation
import Observation

@MainActor
@Observable
final class PaywallViewModel {
    private(set) var isLoading = false
    private(set) var purchasingID: String?
    private(set) var isRestoring = false
    private(set) var errorMessage: String?
    private(set) var successMessage: String?

    @ObservationIgnored let premium: PremiumService
    @ObservationIgnored private let onPurchased: @MainActor () async -> Void

    init(premium: PremiumService, onPurchased: @escaping @MainActor () async -> Void = {}) {
        self.premium = premium
        self.onPurchased = onPurchased
    }

    func load() async {
        guard premium.isPurchasingAvailable, premium.packages.isEmpty else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            try await premium.loadPackages()
        } catch {
            errorMessage = "Couldn't load plans. Check your connection and try again."
        }
    }

    func purchase(_ package: PremiumPackage) async {
        guard purchasingID == nil else { return }
        purchasingID = package.id
        errorMessage = nil
        defer { purchasingID = nil }
        do {
            if try await premium.purchase(package) {
                // RevenueCat's webhook updates the backend; refresh the profile
                // so the backend-side status matches.
                await onPurchased()
                successMessage = if let trial = package.trial {
                    "Your \(trial.label) has started 🎉 Enjoy LABBY TV Pro. Cancel anytime before it ends and you won't be charged."
                } else {
                    "Welcome to LABBY TV Pro!"
                }
            }
        } catch {
            errorMessage = "The purchase didn't go through. \(error.localizedDescription)"
        }
    }

    func restore() async {
        guard !isRestoring else { return }
        isRestoring = true
        errorMessage = nil
        defer { isRestoring = false }
        do {
            try await premium.restore()
            await onPurchased()
            successMessage = premium.isPremium ? "Your subscription has been restored." : "No active subscription was found for this Apple ID."
        } catch {
            errorMessage = "Couldn't restore purchases. \(error.localizedDescription)"
        }
    }
}
