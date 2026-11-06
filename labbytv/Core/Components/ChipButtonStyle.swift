import SwiftUI

/// Category chip: yellow when selected, white when focused.
struct ChipButtonStyle: ButtonStyle {
    let isSelected: Bool

    func makeBody(configuration: Configuration) -> some View {
        ChipButtonBody(configuration: configuration, isSelected: isSelected)
    }
}

private struct ChipButtonBody: View {
    let configuration: ButtonStyleConfiguration
    let isSelected: Bool
    @Environment(\.isFocused) private var isFocused

    var body: some View {
        configuration.label
            .font(AppFonts.caption)
            .lineLimit(1)
            .foregroundStyle(isFocused || isSelected ? AppColors.background : AppColors.textPrimary)
            .padding(.horizontal, Spacing.m)
            .padding(.vertical, Spacing.s - 4)
            .background(Capsule().fill(background))
            .scaleEffect(isFocused ? 1.08 : 1)
            .animation(.easeOut(duration: 0.15), value: isFocused)
    }

    private var background: Color {
        if isFocused { return AppColors.textPrimary }
        if isSelected { return AppColors.accent }
        return AppColors.surface
    }
}
