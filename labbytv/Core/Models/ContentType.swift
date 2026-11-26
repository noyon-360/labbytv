import Foundation

nonisolated enum ContentType: String, Sendable, CaseIterable, Hashable {
    case channels
    case movies
    case series

    /// `/server/connect-tv` wants `channels | movies | series`.
    var catalogType: String { rawValue }

    /// `/category` wants `live` instead of `channels`.
    var categoryType: String {
        switch self {
        case .channels: "live"
        case .movies: "movies"
        case .series: "series"
        }
    }

    /// `/server/get-play-url` wants `live | movie | series`.
    var streamType: String {
        switch self {
        case .channels: "live"
        case .movies: "movie"
        case .series: "series"
        }
    }

    var title: String {
        switch self {
        case .channels: "Live TV"
        case .movies: "Movies"
        case .series: "Series"
        }
    }
}

nonisolated extension ContentType {
    /// Watch history's `videoType` (`live | movie | series`).
    init?(historyVideoType: String) {
        switch historyVideoType {
        case "live": self = .channels
        case "movie": self = .movies
        case "series": self = .series
        default: return nil
        }
    }
}
