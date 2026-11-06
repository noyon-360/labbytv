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
