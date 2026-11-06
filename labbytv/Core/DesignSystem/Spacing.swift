import CoreGraphics

enum Spacing {
    static let xs: CGFloat = 8
    static let s: CGFloat = 16
    static let m: CGFloat = 24
    static let l: CGFloat = 40
    static let xl: CGFloat = 60
    static let xxl: CGFloat = 90

    static let cornerRadius: CGFloat = 16

    // Grid sizes that fit the 1760-pt-wide TV safe area.
    static let posterWidth: CGFloat = 240
    static let channelTileWidth: CGFloat = 320
    static let gridSpacing: CGFloat = 40
}
