import SwiftUI

/// Focus lift + shadow for posters and tiles. Together with the yellow
/// outline (`focusedArtwork`) and the white caption panel (`CardCaption`)
/// this makes the selected card obvious from across the room.
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
            .scaleEffect(configuration.isPressed ? 1.04 : (isFocused ? 1.12 : 1))
            .shadow(color: .black.opacity(isFocused ? 0.75 : 0), radius: 24, y: 16)
            .brightness(isFocused ? 0.05 : 0)
            .zIndex(isFocused ? 1 : 0)
            .animation(.easeOut(duration: 0.18), value: isFocused)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}
