import Foundation

/// `data` of `/watch-history/history` (`history`) and `/favorites` (`favorites`).
nonisolated struct WatchHistoryPage: Decodable, Sendable {
    let items: [WatchHistoryItem]

    private enum CodingKeys: String, CodingKey {
        case history, favorites
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let history = try? container.decode(LossyArray<WatchHistoryItem>.self, forKey: .history) {
            items = history.elements
        } else if let favorites = try? container.decode(LossyArray<WatchHistoryItem>.self, forKey: .favorites) {
            items = favorites.elements
        } else {
            items = []
        }
    }
}
