import SwiftUI

/// TV sizes, readable from about 3 m. Body text never goes below 29 pt;
/// `caption` is only for secondary metadata (times, ratings).
enum AppFonts {
    static let largeTitle = Font.system(size: 76, weight: .bold)
    static let title = Font.system(size: 57, weight: .bold)
    static let headline = Font.system(size: 38, weight: .semibold)
    static let body = Font.system(size: 29)
    static let bodyBold = Font.system(size: 29, weight: .semibold)
    static let button = Font.system(size: 31, weight: .semibold)
    static let caption = Font.system(size: 25, weight: .medium)
}
