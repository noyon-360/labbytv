import Foundation

nonisolated enum AppTab: String, CaseIterable, Identifiable, Hashable, Sendable {
    case home, live, guide, movies, series, search, profile

    var id: String { rawValue }

    var title: String {
        switch self {
        case .home: "Home"
        case .live: "Live TV"
        case .guide: "Guide"
        case .movies: "Movies"
        case .series: "Series"
        case .search: "Search"
        case .profile: "Profile"
        }
    }

    var symbol: String {
        switch self {
        case .home: "house"
        case .live: "play.tv"
        case .guide: "list.bullet.rectangle.portrait"
        case .movies: "film"
        case .series: "tv.and.mediabox"
        case .search: "magnifyingglass"
        case .profile: "person.crop.circle"
        }
    }
}
