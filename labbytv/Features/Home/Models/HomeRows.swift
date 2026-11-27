import Foundation

/// Row rules for Home, same as the Flutter TV Home (`home_rows.dart`,
/// client doc "Android TV V1"): Recently Watched and Recently Added.
nonisolated enum HomeRows {
    /// Everything watched lately (channels too), newest first, once each.
    static func recentlyWatched(_ history: [WatchHistoryItem], limit: Int = 20) -> [WatchHistoryItem] {
        let sorted = history.enumerated().sorted { a, b in
            let ta = a.element.lastWatchedAt ?? .distantPast
            let tb = b.element.lastWatchedAt ?? .distantPast
            return ta != tb ? ta > tb : a.offset < b.offset
        }
        var seen = Set<String>()
        return Array(sorted.map(\.element).filter { seen.insert("\($0.videoType):\($0.videoId)").inserted }.prefix(limit))
    }

    /// Newest first by the provider's "added" time. Empty when no item has
    /// one: the row would just repeat Popular in the same order.
    static func recentlyAdded<Item>(_ items: [Item], limit: Int = 20, added: (Item) -> Int?) -> [Item] {
        guard items.contains(where: { (added($0) ?? 0) > 0 }) else { return [] }
        let sorted = items.enumerated().sorted { a, b in
            let ta = added(a.element) ?? -1
            let tb = added(b.element) ?? -1
            return ta != tb ? ta > tb : a.offset < b.offset
        }
        return Array(sorted.map(\.element).prefix(limit))
    }

    /// Caption under a history card: the category badge when the record has
    /// one (client, Android TV V1), with season and episode for episodes.
    static func caption(for item: WatchHistoryItem) -> String {
        let kind: String
        switch item.videoType {
        case "live": kind = "Live TV"
        case "series": kind = item.seasonNumber.map { "S\($0) E\(item.episodeNumber ?? 0)" } ?? "Series"
        default: kind = "Movie"
        }
        guard let category = item.categoryName else { return kind }
        return item.videoType == "series" && item.seasonNumber != nil ? "\(kind) · \(category)" : category
    }
}
