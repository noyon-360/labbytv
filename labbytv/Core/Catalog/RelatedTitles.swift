import Foundation

/// "More Like This" on detail screens: other titles from the same category,
/// as the phone app shows. Only for a known category, which the parental
/// lock has already let the user into, so locked titles can't leak in.
nonisolated enum RelatedTitles {
    static let fetchLimit = 30
    static let shelfLimit = 20

    static func pick<Item: CatalogItem>(_ items: [Item], excluding id: Int, limit: Int = shelfLimit) -> [Item] {
        var seen: Set<Int> = [id]
        return Array(items.filter { seen.insert($0.id).inserted }.prefix(limit))
    }

    static func load<Item: CatalogItem>(_ type: ContentType, categoryID: String, excluding id: Int, catalog: any CatalogRepository) async -> [Item] {
        guard !categoryID.isEmpty else { return [] }
        let items: [Item] = (try? await catalog.items(type, categoryID: categoryID, search: nil, page: 1, limit: fetchLimit)) ?? []
        return pick(items, excluding: id)
    }
}
