import Foundation

/// `data` of `/watch-history/status/{videoId}`. Mirrors Flutter `VideoStatusModel`.
nonisolated struct VideoStatus: Decodable, Sendable {
    let currentTime: Double
    let duration: Double
    let isCompleted: Bool
    let isLoved: Bool

    private enum CodingKeys: String, CodingKey {
        case currentTime, duration, isCompleted, isLoved
    }

    init(currentTime: Double = 0, duration: Double = 0, isCompleted: Bool = false, isLoved: Bool = false) {
        self.currentTime = currentTime
        self.duration = duration
        self.isCompleted = isCompleted
        self.isLoved = isLoved
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        currentTime = container.lenientDouble(.currentTime) ?? 0
        duration = container.lenientDouble(.duration) ?? 0
        isCompleted = container.lenientBool(.isCompleted) ?? false
        isLoved = container.lenientBool(.isLoved) ?? false
    }

    /// Flutter's rule: resume unless finished, or < 10 s left, or > 95 % watched.
    var resumePosition: Double? {
        guard !isCompleted, currentTime > 0 else { return nil }
        let remaining = duration - currentTime
        let fraction = duration > 0 ? currentTime / duration : 0
        if remaining < 10 || fraction > 0.95 { return nil }
        return currentTime
    }
}
