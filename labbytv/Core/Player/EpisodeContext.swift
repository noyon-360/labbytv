import Foundation

/// The series an episode belongs to. Watch history only stores the episode
/// id, so the TV app remembers this locally to resume episodes from Home.
nonisolated struct EpisodeContext: Codable, Hashable, Sendable {
    let seriesID: Int
    let seriesTitle: String
    let cover: String
}
