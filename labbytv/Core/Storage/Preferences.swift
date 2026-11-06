import Foundation

/// Non-secret settings in UserDefaults. Nothing here may contain credentials.
@MainActor
final class Preferences {
    private let defaults: UserDefaults
    private let episodeContextKey = "episodeContexts"
    private let maxEpisodeContexts = 300
    private let aspectModeKey = "player.aspectMode"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var videoAspectMode: VideoAspectMode {
        get { defaults.string(forKey: aspectModeKey).flatMap(VideoAspectMode.init(rawValue:)) ?? .fit }
        set { defaults.set(newValue.rawValue, forKey: aspectModeKey) }
    }

    /// Parental lock: locked Xtream category ids. Stored per content type
    /// because Xtream category ids are only unique within one type.
    func lockedCategoryIDs(for type: ContentType) -> Set<String> {
        Set(defaults.stringArray(forKey: lockedKey(type)) ?? [])
    }

    func setLockedCategoryIDs(_ ids: Set<String>, for type: ContentType) {
        defaults.set(ids.sorted(), forKey: lockedKey(type))
    }

    private func lockedKey(_ type: ContentType) -> String {
        "parental.locked.\(type.rawValue)"
    }

    func episodeContext(for episodeID: String) -> EpisodeContext? {
        loadEpisodeContexts()[episodeID]?.context
    }

    func remember(_ context: EpisodeContext, for episode: Episode) {
        var all = loadEpisodeContexts()
        all[episode.id] = StoredEpisode(context: context, containerExtension: episode.containerExtension, season: episode.season, number: episode.episodeNum, title: episode.title, savedAt: .now)
        if all.count > maxEpisodeContexts {
            let oldest = all.sorted { $0.value.savedAt < $1.value.savedAt }.prefix(all.count - maxEpisodeContexts)
            oldest.forEach { all.removeValue(forKey: $0.key) }
        }
        if let data = try? JSONEncoder().encode(all) {
            defaults.set(data, forKey: episodeContextKey)
        }
    }

    /// Rebuilds a playable episode from what was saved when it was last played.
    func episode(for episodeID: String) -> (Episode, EpisodeContext)? {
        guard let stored = loadEpisodeContexts()[episodeID] else { return nil }
        let episode = Episode(id: episodeID, episodeNum: stored.number, title: stored.title, season: stored.season, containerExtension: stored.containerExtension)
        return (episode, stored.context)
    }

    private struct StoredEpisode: Codable {
        let context: EpisodeContext
        let containerExtension: String
        let season: Int
        let number: Int
        let title: String
        let savedAt: Date
    }

    private func loadEpisodeContexts() -> [String: StoredEpisode] {
        guard let data = defaults.data(forKey: episodeContextKey),
              let decoded = try? JSONDecoder().decode([String: StoredEpisode].self, from: data) else {
            return [:]
        }
        return decoded
    }
}
