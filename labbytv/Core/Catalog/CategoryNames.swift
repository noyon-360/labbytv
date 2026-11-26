import Foundation

/// Category names by id, so history and favourite updates can send
/// `categoryName` for category badges (client, Android TV V1 #7). Loads each
/// type's list once per playlist; Xtream category ids only mean something
/// within one provider and one content type.
actor CategoryNames {
    private let catalog: any CatalogRepository
    private let playlistID: @Sendable () async -> String?
    private var cachedPlaylist: String?
    private var names: [ContentType: [String: String]] = [:]

    init(catalog: any CatalogRepository, playlistID: @escaping @Sendable () async -> String?) {
        self.catalog = catalog
        self.playlistID = playlistID
    }

    /// `nil` when the id is unknown or the list can't be loaded. Never
    /// throws: a missing badge must not fail a favourite.
    func name(for type: ContentType, id: String) async -> String? {
        guard !id.isEmpty else { return nil }
        let playlist = await playlistID()
        if playlist != cachedPlaylist {
            cachedPlaylist = playlist
            names = [:]
        }
        if names[type] == nil {
            guard let list = try? await catalog.categories(for: type) else { return nil }
            names[type] = Dictionary(list.map { ($0.id, $0.name) }, uniquingKeysWith: { first, _ in first })
        }
        return names[type]?[id]
    }
}
