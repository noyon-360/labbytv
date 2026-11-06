import SwiftUI

/// The white pill button from the Flutter app, with a tvOS focus lift.
/// A custom style drops the system focus effect, so we draw our own.
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        PrimaryButtonBody(configuration: configuration)
    }
}

private struct PrimaryButtonBody: View {
    let configuration: ButtonStyleConfiguration
    @Environment(\.isFocused) private var isFocused
    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        configuration.label
            .font(AppFonts.button)
            .foregroundStyle(isFocused ? AppColors.background : AppColors.textPrimary)
            .frame(maxWidth: .infinity, minHeight: 80)
            .background(
                Capsule().fill(isFocused ? AppColors.textPrimary : AppColors.surfaceRaised)
            )
            .opacity(isEnabled ? 1 : 0.5)
            .scaleEffect(configuration.isPressed ? 0.97 : (isFocused ? 1.05 : 1))
            .shadow(color: .black.opacity(isFocused ? 0.5 : 0), radius: 16, y: 10)
            .animation(.easeOut(duration: 0.15), value: isFocused)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

#Preview {
    VStack(spacing: Spacing.l) {
        Button("Sign In") {}
        Button("Disabled") {}.disabled(true)
    }
    .buttonStyle(PrimaryButtonStyle())
    .frame(width: 600)
    .padding()
    .background(AppColors.background)
}
