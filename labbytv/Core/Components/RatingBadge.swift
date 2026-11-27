import Foundation

/// "★ 4.2" for a poster, or nothing when the provider sent no rating.
nonisolated enum RatingBadge {
    static func text(_ rating5Based: Double) -> String? {
        guard rating5Based > 0 else { return nil }
        return "★ \(String(format: "%.1f", min(rating5Based, 5)))"
    }
}
