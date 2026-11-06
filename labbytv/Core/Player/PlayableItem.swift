import Foundation

/// What the full-screen player is asked to play.
nonisolated enum PlayableItem: Identifiable, Hashable, Sendable {
    /// `lineup` is the channel list the user came from (the current
    /// category), used for channel up/down.
    case live(Channel, lineup: [Channel])
    case movie(id: Int, title: String, thumbnail: String)
    case episode(Episode, context: EpisodeContext)

    var id: String {
        switch self {
        case .live(let channel, _): "live-\(channel.id)"
        case .movie(let id, _, _): "movie-\(id)"
        case .episode(let episode, _): "episode-\(episode.id)"
        }
    }

    var title: String {
        switch self {
        case .live(let channel, _): channel.name
        case .movie(_, let title, _): title
        case .episode(let episode, let context):
            "\(context.seriesTitle) · S\(episode.season) E\(episode.episodeNum)" + (episode.title.isEmpty ? "" : " · \(episode.title)")
        }
    }

    var isLive: Bool {
        if case .live = self { return true }
        return false
    }
}
