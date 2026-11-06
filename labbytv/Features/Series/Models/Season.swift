import Foundation

/// Mirrors Flutter `Season` (`get_series_info.seasons[]`).
nonisolated struct Season: Decodable, Sendable, Hashable, Identifiable {
    let seasonNumber: Int
    let name: String
    let overview: String
    let cover: String

    var id: Int { seasonNumber }

    init(seasonNumber: Int, name: String, overview: String = "", cover: String = "") {
        self.seasonNumber = seasonNumber
        self.name = name
        self.overview = overview
        self.cover = cover
    }

    private enum CodingKeys: String, CodingKey {
        case name, overview, cover
        case seasonNumber = "season_number"
        case coverBig = "cover_big"
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        seasonNumber = container.lenientInt(.seasonNumber) ?? 0
        name = container.lenientString(.name) ?? ""
        overview = container.lenientString(.overview) ?? ""
        let cover = container.lenientString(.cover) ?? ""
        self.cover = cover.isEmpty ? (container.lenientString(.coverBig) ?? "") : cover
    }
}
