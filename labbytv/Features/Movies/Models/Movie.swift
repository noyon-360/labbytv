import Foundation

/// A VOD item. Mirrors Flutter `MoviesResponseModel` (Xtream `get_vod_streams`).
nonisolated struct Movie: CatalogItem {
    let id: Int
    let name: String
    let streamIcon: String
    let rating: String
    let rating5Based: Double
    let categoryId: String
    let containerExtension: String

    var title: String { name }
    var imageURL: URL? { URL(xtreamImage: streamIcon) }

    init(id: Int, name: String, streamIcon: String = "", rating: String = "", rating5Based: Double = 0, categoryId: String = "", containerExtension: String = "") {
        self.id = id
        self.name = name
        self.streamIcon = streamIcon
        self.rating = rating
        self.rating5Based = rating5Based
        self.categoryId = categoryId
        self.containerExtension = containerExtension
    }

    private enum CodingKeys: String, CodingKey {
        case name, rating
        case streamId = "stream_id"
        case streamIcon = "stream_icon"
        case rating5Based = "rating_5based"
        case categoryId = "category_id"
        case containerExtension = "container_extension"
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = container.lenientInt(.streamId) ?? 0
        name = container.lenientString(.name) ?? ""
        streamIcon = container.lenientString(.streamIcon) ?? ""
        rating = container.lenientString(.rating) ?? ""
        rating5Based = container.lenientDouble(.rating5Based) ?? 0
        categoryId = container.lenientString(.categoryId) ?? ""
        containerExtension = container.lenientString(.containerExtension) ?? ""
    }
}
