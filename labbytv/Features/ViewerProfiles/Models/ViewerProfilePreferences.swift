import Foundation

/// Per-profile playback preferences. Stored by the backend; the apps don't
/// edit them yet.
nonisolated struct ViewerProfilePreferences: Decodable, Sendable, Hashable {
    /// Language codes; empty = the stream's default.
    var subtitleLanguage = ""
    var audioLanguage = ""
    var autoplayNextEpisode = true

    init() {}

    private enum CodingKeys: String, CodingKey {
        case subtitleLanguage, audioLanguage, autoplayNextEpisode
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        subtitleLanguage = container.lenientString(.subtitleLanguage) ?? ""
        audioLanguage = container.lenientString(.audioLanguage) ?? ""
        autoplayNextEpisode = (try? container.decodeIfPresent(Bool.self, forKey: .autoplayNextEpisode)) ?? true
    }
}
