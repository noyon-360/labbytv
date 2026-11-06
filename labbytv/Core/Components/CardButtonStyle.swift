import SwiftUI

/// Focus lift + shadow for posters and tiles. The title under the artwork
/// brightens with focus so the selection is readable from the sofa.
struct CardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        CardButtonBody(configuration: configuration)
    }
}

private struct CardButtonBody: View {
    let configuration: ButtonStyleConfiguration
    @Environment(\.isFocused) private var isFocused

    var body: some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 1.02 : (isFocused ? 1.08 : 1))
            .shadow(color: .black.opacity(isFocused ? 0.6 : 0), radius: 20, y: 14)
            .brightness(isFocused ? 0.04 : 0)
            .zIndex(isFocused ? 1 : 0)
            .animation(.easeOut(duration: 0.18), value: isFocused)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}
