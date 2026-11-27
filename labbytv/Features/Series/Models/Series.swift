import Foundation

/// A series in the catalog. Mirrors Flutter `SeriesResponesModel` (Xtream `get_series`).
nonisolated struct Series: CatalogItem {
    let id: Int
    let name: String
    let cover: String
    let plot: String
    let genre: String
    let releaseDate: String
    let rating5Based: Double
    let categoryId: String
    /// Provider's last change (Unix seconds), for Recently Added on Home.
    let lastModified: Int?

    var title: String { name }
    var imageURL: URL? { URL(xtreamImage: cover) }

    init(id: Int, name: String, cover: String = "", plot: String = "", genre: String = "", releaseDate: String = "", rating5Based: Double = 0, categoryId: String = "", lastModified: Int? = nil) {
        self.id = id
        self.name = name
        self.cover = cover
        self.plot = plot
        self.genre = genre
        self.releaseDate = releaseDate
        self.rating5Based = rating5Based
        self.categoryId = categoryId
        self.lastModified = lastModified
    }

    private enum CodingKeys: String, CodingKey {
        case name, cover, plot, genre, releaseDate
        case seriesId = "series_id"
        case releaseDateSnake = "release_date"
        case rating5Based = "rating_5based"
        case categoryId = "category_id"
        case lastModified = "last_modified"
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = container.lenientInt(.seriesId) ?? 0
        name = container.lenientString(.name) ?? ""
        cover = container.lenientString(.cover) ?? ""
        plot = container.lenientString(.plot) ?? ""
        genre = container.lenientString(.genre) ?? ""
        releaseDate = container.lenientString(.releaseDate) ?? container.lenientString(.releaseDateSnake) ?? ""
        rating5Based = container.lenientDouble(.rating5Based) ?? 0
        categoryId = container.lenientString(.categoryId) ?? ""
        lastModified = container.lenientInt(.lastModified)
    }
}
