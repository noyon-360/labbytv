import AVFoundation

/// How the picture fills the 16:9 screen. Chosen from the player and kept
/// across videos, since it's usually a per-provider preference.
enum VideoAspectMode: String, CaseIterable, Sendable {
    /// Whole picture visible, black bars if the shapes differ.
    case fit
    /// Fills the screen, cropping the edges.
    case fill
    /// Fills the screen, distorting the picture (old 4:3 channels).
    case stretch

    var title: String {
        switch self {
        case .fit: "Fit"
        case .fill: "Zoom"
        case .stretch: "Stretch"
        }
    }

    var videoGravity: AVLayerVideoGravity {
        switch self {
        case .fit: .resizeAspect
        case .fill: .resizeAspectFill
        case .stretch: .resize
        }
    }

    /// VLC has no gravity setting: it crops (fill) or forces an aspect ratio
    /// (stretch) to the screen's shape instead. Apple TV output is always 16:9.
    var vlcCropGeometry: String? { self == .fill ? "16:9" : nil }
    var vlcAspectRatio: String? { self == .stretch ? "16:9" : nil }
}
