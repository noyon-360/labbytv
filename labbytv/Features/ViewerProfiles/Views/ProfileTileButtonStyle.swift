import SwiftUI

/// "Who's Watching" tile: the avatar lifts with a white outline and the
/// name turns white when focused, like the Apple TV system profile picker.
struct ProfileTileButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        ProfileTileBody(configuration: configuration)
    }
}

private struct ProfileTileBody: View {
    let configuration: ButtonStyleConfiguration
    @Environment(\.isFocused) private var isFocused

    var body: some View {
        configuration.label
            .foregroundStyle(isFocused ? AppColors.textPrimary : AppColors.textSecondary)
            .scaleEffect(configuration.isPressed ? 1.03 : (isFocused ? 1.1 : 1))
            .shadow(color: .black.opacity(isFocused ? 0.7 : 0), radius: 24, y: 16)
            .animation(.easeOut(duration: 0.18), value: isFocused)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
            .environment(\.profileTileIsFocused, isFocused)
    }
}

extension EnvironmentValues {
    /// Lets the tile's avatar draw its focus outline.
    @Entry var profileTileIsFocused = false
}
