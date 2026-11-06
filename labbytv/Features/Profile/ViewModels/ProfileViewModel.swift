import Foundation
import Observation

@MainActor
@Observable
final class ProfileViewModel {
    private(set) var isLoading = false

    @ObservationIgnored private let environment: AppEnvironment

    init(environment: AppEnvironment) {
        self.environment = environment
    }

    var user: User? { environment.session.currentUser }
    var playlistName: String { environment.session.activePlaylist?.name ?? "None" }
    var isPremium: Bool { environment.premium.isPremium }
    var parentalLockIsOn: Bool { environment.parentalLock.hasPin }

    var planLabel: String {
        if environment.premium.isInFreeTrial { return "LABBY TV Pro · Free trial" }
        return isPremium ? "LABBY TV Pro" : "Free plan"
    }

    /// Why the lock settings can't open (free or trial user), or nil.
    var parentalLockBlockMessage: String? {
        ParentalLockRules.premiumBlockMessage(
            hasPin: environment.parentalLock.hasPin,
            isPremium: environment.premium.isPremium,
            isFreeTrial: environment.premium.isInFreeTrial
        )
    }

    /// Asks for the PIN (if one is set) before opening the lock settings.
    func unlockParentalSettings() async -> Bool {
        await environment.parentalLock.verifyParent()
    }

    var appVersion: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "?"
        return "Version \(version) (\(build))"
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }
        await environment.refreshProfile()
    }

    func signOut() async {
        await environment.signOut()
    }
}
