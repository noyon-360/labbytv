import Foundation

/// Mirrors Flutter `WatchHistoryModel`.
nonisolated struct WatchHistoryItem: Decodable, Sendable, Hashable, Identifiable {
    let id: String
    let videoId: String
    /// `movie`, `series` or `live`.
    let videoType: String
    let seasonNumber: Int?
    let episodeNumber: Int?
    let name: String
    let thumbnail: String
    let currentTime: Double
    let duration: Double
    let progressPercentage: Double
    let isCompleted: Bool
    let isLoved: Bool
    /// Saved with the record since the profiles update; older records have none.
    let categoryName: String?
    let lastWatchedAt: Date?

    var imageURL: URL? { URL(xtreamImage: thumbnail) }
    var streamID: Int? { Int(videoId) }
    var progress: Double { duration > 0 ? min(1, currentTime / duration) : progressPercentage / 100 }

    private enum CodingKeys: String, CodingKey {
        case id = "_id"
        case videoId, videoType, seasonNumber, episodeNumber, name, title, thumbnail
        case currentTime, duration, progressPercentage, isCompleted, isLoved
        case categoryName, lastWatchedAt, updatedAt
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = container.lenientString(.id) ?? UUID().uuidString
        videoId = container.lenientString(.videoId) ?? ""
        videoType = (container.lenientString(.videoType) ?? "").lowercased()
        seasonNumber = container.lenientInt(.seasonNumber)
        episodeNumber = container.lenientInt(.episodeNumber)
        name = container.lenientString(.name) ?? container.lenientString(.title) ?? ""
        thumbnail = container.lenientString(.thumbnail) ?? ""
        currentTime = container.lenientDouble(.currentTime) ?? 0
        duration = container.lenientDouble(.duration) ?? 0
        progressPercentage = container.lenientDouble(.progressPercentage) ?? 0
        isCompleted = container.lenientBool(.isCompleted) ?? false
        isLoved = container.lenientBool(.isLoved) ?? false
        let category = container.lenientString(.categoryName)?.trimmingCharacters(in: .whitespaces)
        categoryName = category?.isEmpty == false ? category : nil
        lastWatchedAt = Self.date(container.lenientString(.lastWatchedAt)) ?? Self.date(container.lenientString(.updatedAt))
    }

    /// Mongo dates arrive as ISO 8601 with milliseconds.
    private static func date(_ string: String?) -> Date? {
        guard let string else { return nil }
        return (try? Date.ISO8601FormatStyle(includingFractionalSeconds: true).parse(string))
            ?? (try? Date.ISO8601FormatStyle().parse(string))
    }
}
