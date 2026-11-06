import Foundation

/// Anything shown in a catalog grid: a channel, movie or series.
nonisolated protocol CatalogItem: Decodable, Sendable, Identifiable, Hashable where ID == Int {
    var id: Int { get }
    var title: String { get }
    var imageURL: URL? { get }
    /// Xtream category, used by the parental lock to hide locked items.
    var categoryId: String { get }
}

nonisolated extension URL {
    /// Xtream image fields are often empty strings or junk; only accept http(s).
    init?(xtreamImage string: String?) {
        guard let string, !string.isEmpty,
              let url = URL(string: string.trimmingCharacters(in: .whitespaces)),
              let scheme = url.scheme?.lowercased(), scheme == "http" || scheme == "https" else {
            return nil
        }
        self = url
    }
}
