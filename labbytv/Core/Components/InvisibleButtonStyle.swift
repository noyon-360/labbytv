import SwiftUI

/// A focusable button with no visible focus effect, used as a full-screen
/// remote target while player controls are hidden.
struct InvisibleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.contentShape(Rectangle())
    }
}
