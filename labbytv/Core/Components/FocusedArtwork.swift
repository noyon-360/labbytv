import SwiftUI

/// Focus look shared by posters and channel tiles (client feedback #10):
/// a yellow outline on the artwork, so the selection reads from across the
/// room. Works inside any `Button` label: `isFocused` follows the button.
struct FocusedArtwork: ViewModifier {
    @Environment(\.isFocused) private var isFocused

    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: Spacing.cornerRadius, style: .continuous)
                    .strokeBorder(AppColors.accent, lineWidth: isFocused ? 6 : 0)
            )
            .animation(.easeOut(duration: 0.15), value: isFocused)
    }
}

extension View {
    func focusedArtwork() -> some View { modifier(FocusedArtwork()) }
}
