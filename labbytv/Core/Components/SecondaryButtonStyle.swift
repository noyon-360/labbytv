import SwiftUI

/// Text-sized pill for secondary actions (Retry, Sign Up, Restore…).
struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        SecondaryButtonBody(configuration: configuration)
    }
}

private struct SecondaryButtonBody: View {
    let configuration: ButtonStyleConfiguration
    @Environment(\.isFocused) private var isFocused

    var body: some View {
        configuration.label
            .font(AppFonts.bodyBold)
            .foregroundStyle(isFocused ? AppColors.background : AppColors.textPrimary)
            .padding(.horizontal, Spacing.l)
            .padding(.vertical, Spacing.s)
            .background(Capsule().fill(isFocused ? AppColors.textPrimary : AppColors.surface))
            .scaleEffect(configuration.isPressed ? 0.97 : (isFocused ? 1.06 : 1))
            .shadow(color: .black.opacity(isFocused ? 0.5 : 0), radius: 12, y: 8)
            .animation(.easeOut(duration: 0.15), value: isFocused)
    }
}
