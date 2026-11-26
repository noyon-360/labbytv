import SwiftUI

/// The 12 preset avatars (`avatar_01`…`avatar_12`, the backend's list).
/// Drawn in code (colour + symbol) so every app draws the same set without
/// shipping artwork. Colours match Flutter `avatarPresets` exactly; the
/// symbols are the closest SF Symbols to its Material icons.
nonisolated struct AvatarPreset: Sendable, Hashable {
    let key: String
    /// 0xRRGGBB, as in the Flutter table.
    let rgb: UInt32
    let symbol: String

    static let defaultKey = "avatar_01"

    static let all: [AvatarPreset] = [
        AvatarPreset(key: "avatar_01", rgb: 0xFBB41E, symbol: "face.smiling"), // LABBY yellow
        AvatarPreset(key: "avatar_02", rgb: 0xE53935, symbol: "face.smiling.inverse"),
        AvatarPreset(key: "avatar_03", rgb: 0x1E88E5, symbol: "person.fill"),
        AvatarPreset(key: "avatar_04", rgb: 0x43A047, symbol: "person.crop.circle"),
        AvatarPreset(key: "avatar_05", rgb: 0x8E24AA, symbol: "sparkles"),
        AvatarPreset(key: "avatar_06", rgb: 0xFB8C00, symbol: "sun.max.fill"),
        AvatarPreset(key: "avatar_07", rgb: 0x00897B, symbol: "pawprint.fill"),
        AvatarPreset(key: "avatar_08", rgb: 0xD81B60, symbol: "star.fill"),
        AvatarPreset(key: "avatar_09", rgb: 0x3949AB, symbol: "airplane"),
        AvatarPreset(key: "avatar_10", rgb: 0x6D4C41, symbol: "gamecontroller.fill"),
        AvatarPreset(key: "avatar_11", rgb: 0x00ACC1, symbol: "music.note"),
        AvatarPreset(key: "avatar_12", rgb: 0x546E7A, symbol: "soccerball"),
    ]

    /// Unknown keys (a newer backend list) fall back to the first preset.
    static func preset(for key: String) -> AvatarPreset {
        all.first { $0.key == key } ?? all[0]
    }

    var color: Color {
        Color(
            red: Double((rgb >> 16) & 0xFF) / 255,
            green: Double((rgb >> 8) & 0xFF) / 255,
            blue: Double(rgb & 0xFF) / 255
        )
    }
}
