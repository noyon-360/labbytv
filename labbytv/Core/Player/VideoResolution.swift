import CoreGraphics

/// SD / HD / FHD / 4K from the decoded picture, like the Android TV player
/// (`liveQualityLabel`). Uses the width too, so a 1920×800 film counts as
/// FHD rather than HD.
nonisolated enum VideoResolution {
    static func label(for size: CGSize) -> String? {
        guard size.width > 0, size.height > 0 else { return nil }
        let lines = max(size.height, size.width * 9 / 16)
        if lines >= 2000 { return "4K" }
        if lines >= 1000 { return "FHD" }
        if lines >= 700 { return "HD" }
        return "SD"
    }
}
