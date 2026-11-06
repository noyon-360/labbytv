import SwiftUI

/// A key on the PIN pad: a rounded tile that turns white and lifts on focus.
struct PinKeyButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        PinKeyButtonBody(configuration: configuration)
    }
}

private struct PinKeyButtonBody: View {
    let configuration: ButtonStyleConfiguration
    @Environment(\.isFocused) private var isFocused

    var body: some View {
        configuration.label
            .font(AppFonts.headline)
            .foregroundStyle(isFocused ? AppColors.background : AppColors.textPrimary)
            .frame(width: 150, height: 96)
            .background(
                RoundedRectangle(cornerRadius: Spacing.cornerRadius)
                    .fill(isFocused ? AppColors.textPrimary : AppColors.surface)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : (isFocused ? 1.1 : 1))
            .shadow(color: .black.opacity(isFocused ? 0.5 : 0), radius: 14, y: 8)
            .animation(.easeOut(duration: 0.15), value: isFocused)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

#Preview {
    HStack(spacing: Spacing.m) {
        Button("1") {}
        Button { } label: { Image(systemName: "delete.left") }
    }
    .buttonStyle(PinKeyButtonStyle())
    .padding()
    .background(AppColors.background)
}
