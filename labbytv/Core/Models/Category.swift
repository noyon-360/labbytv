import Foundation

/// An Xtream category. Mirrors Flutter `GenreModel`.
nonisolated struct Category: Decodable, Sendable, Hashable, Identifiable {
    let id: String
    let name: String

    /// The "All" chip, which loads the uncategorised catalog.
    static let all = Category(id: "", name: "All")

    init(id: String, name: String) {
        self.id = id
        self.name = name
    }

    private enum CodingKeys: String, CodingKey {
        case id = "category_id"
        case name = "category_name"
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = container.lenientString(.id) ?? ""
        name = container.lenientString(.name) ?? ""
    }
}
