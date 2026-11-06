import Foundation

/// Speeds offered for movies and episodes. Live TV always plays at 1×
/// because it can't run ahead of the broadcast.
enum PlaybackSpeed {
    static let options: [Float] = [0.5, 0.75, 1, 1.25, 1.5, 2]
    static let normal: Float = 1

    /// "0.5×", "1×", "1.25×".
    static func label(for rate: Float) -> String {
        let text = rate.formatted(.number.precision(.fractionLength(0...2)).locale(Locale(identifier: "en_US_POSIX")))
        return "\(text)×"
    }
}
