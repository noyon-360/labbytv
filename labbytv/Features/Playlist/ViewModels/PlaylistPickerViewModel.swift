import Foundation
import Observation

@MainActor
@Observable
final class PlaylistPickerViewModel {
    private(set) var playlists: [Playlist] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    @ObservationIgnored private let repository: any PlaylistRepository
    @ObservationIgnored private let session: SessionStore
    /// At first sign-in a single playlist is picked for the user; when
    /// switching from Profile the list is always shown.
    @ObservationIgnored private let autoSelectSingle: Bool

    init(repository: any PlaylistRepository, session: SessionStore, autoSelectSingle: Bool) {
        self.repository = repository
        self.session = session
        self.autoSelectSingle = autoSelectSingle
    }

    var activePlaylistID: String? { session.activePlaylist?.id }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            playlists = try await repository.playlists()
            if autoSelectSingle, playlists.count == 1, let only = playlists.first {
                select(only)
            }
        } catch is CancellationError {
            return
        } catch {
            errorMessage = (error as? APIError)?.userMessage ?? APIError.unknown.userMessage
        }
    }

    func select(_ playlist: Playlist) {
        session.selectPlaylist(playlist)
    }
}
