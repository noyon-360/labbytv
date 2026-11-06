import Foundation
import Observation

@MainActor
@Observable
final class AddPlaylistViewModel {
    var name = ""
    var serverURL = ""
    var username = ""
    var password = ""
    private(set) var isSaving = false
    private(set) var errorMessage: String?
    private(set) var didSave = false

    @ObservationIgnored private let repository: any PlaylistRepository

    init(repository: any PlaylistRepository) {
        self.repository = repository
    }

    func save() async {
        guard !isSaving else { return }
        let request = AddPlaylistRequest(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            userName: username.trimmingCharacters(in: .whitespacesAndNewlines),
            password: password,
            url: Self.normalizedURL(serverURL)
        )
        if let message = Self.validationMessage(for: request) {
            errorMessage = message
            return
        }
        errorMessage = nil
        isSaving = true
        defer { isSaving = false }
        do {
            try await repository.add(request)
            didSave = true
        } catch is CancellationError {
            return
        } catch {
            errorMessage = (error as? APIError)?.userMessage ?? APIError.unknown.userMessage
        }
    }

    /// Xtream URLs are `http://host:port`; drop a trailing slash so the
    /// backend's `${serverUrl}/player_api.php` doesn't get `//`.
    nonisolated static func normalizedURL(_ raw: String) -> String {
        var url = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        while url.hasSuffix("/") { url.removeLast() }
        if !url.isEmpty, !url.lowercased().hasPrefix("http://"), !url.lowercased().hasPrefix("https://") {
            url = "http://" + url
        }
        return url
    }

    nonisolated static func validationMessage(for request: AddPlaylistRequest) -> String? {
        if request.name.isEmpty { return "Playlist name is required" }
        if URL(string: request.url)?.host() == nil { return "Enter a valid server URL" }
        if request.userName.isEmpty { return "Username is required" }
        if request.password.isEmpty { return "Password is required" }
        return nil
    }
}
