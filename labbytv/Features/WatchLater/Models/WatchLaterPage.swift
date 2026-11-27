import Foundation

/// `data` of `GET /watch-later`: `{ items, pagination }`.
nonisolated struct WatchLaterPage: Decodable, Sendable {
    let items: [WatchLaterItem]

    private enum CodingKeys: String, CodingKey {
        case items
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        items = (try? container.decode(LossyArray<WatchLaterItem>.self, forKey: .items))?.elements ?? []
    }
}
