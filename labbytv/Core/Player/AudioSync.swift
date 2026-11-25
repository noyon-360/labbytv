import Foundation

/// Manual audio sync for the VLC player (client feedback #13).
/// AVPlayer has no audio-delay setting, so this is VLC only.
nonisolated enum AudioSync {
    static let step = 50
    static let limit = 5000

    static func adjusted(_ value: Int, by delta: Int) -> Int {
        min(limit, max(-limit, value + delta))
    }

    static func label(_ milliseconds: Int) -> String {
        switch milliseconds {
        case 0: "In sync (0 ms)"
        case 1...: "Audio \(milliseconds) ms later"
        default: "Audio \(-milliseconds) ms earlier"
        }
    }
}
