import SwiftUI

/// Same palette as Flutter `AppColors` (dark theme only on TV), plus the
/// logo's yellow for focus accents.
enum AppColors {
    static let background = Color.black
    static let surface = Color(red: 0x27 / 255, green: 0x27 / 255, blue: 0x27 / 255)    // containerBgColor
    static let surfaceRaised = Color(red: 0x54 / 255, green: 0x54 / 255, blue: 0x54 / 255) // iconBgColor
    static let textPrimary = Color.white
    static let textSecondary = Color(red: 0xBF / 255, green: 0xBF / 255, blue: 0xBF / 255) // primaryGray
    static let error = Color(red: 0xE5 / 255, green: 0x02 / 255, blue: 0x02 / 255)
    static let success = Color(red: 0x03 / 255, green: 0x9B / 255, blue: 0x06 / 255)
    static let accent = Color(red: 0xFB / 255, green: 0xB4 / 255, blue: 0x1E / 255)  // logo yellow
    static let nowLine = error
}
