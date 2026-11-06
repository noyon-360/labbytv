import Foundation

/// A live channel. Mirrors Flutter `LiveTvModel` (Xtream `get_live_streams`).
nonisolated struct Channel: CatalogItem {
    let id: Int
    let num: Int
    let name: String
    let streamIcon: String
    let epgChannelId: String
    let categoryId: String

    var title: String { name }
    var imageURL: URL? { URL(xtreamImage: streamIcon) }

    init(id: Int, num: Int = 0, name: String, streamIcon: String = "", epgChannelId: String = "", categoryId: String = "") {
        self.id = id
        self.num = num
        self.name = name
        self.streamIcon = streamIcon
        self.epgChannelId = epgChannelId
        self.categoryId = categoryId
    }

    private enum CodingKeys: String, CodingKey {
        case num, name
        case streamId = "stream_id"
        case streamIcon = "stream_icon"
        case epgChannelId = "epg_channel_id"
        case categoryId = "category_id"
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = container.lenientInt(.streamId) ?? 0
        num = container.lenientInt(.num) ?? 0
        name = container.lenientString(.name) ?? ""
        streamIcon = container.lenientString(.streamIcon) ?? ""
        epgChannelId = container.lenientString(.epgChannelId) ?? ""
        categoryId = container.lenientString(.categoryId) ?? ""
    }
}
