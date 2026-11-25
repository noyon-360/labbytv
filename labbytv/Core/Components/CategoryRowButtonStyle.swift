import SwiftUI

/// One row of the category list. Expanded: the category name (yellow when
/// selected, dark on white when focused). Collapsed: only a short marker,
/// so the list becomes a thin rail beside the grid.
struct CategoryRowButtonStyle: ButtonStyle {
    let isSelected: Bool
    let isExpanded: Bool

    func makeBody(configuration: Configuration) -> some View {
        CategoryRowBody(configuration: configuration, isSelected: isSelected, isExpanded: isExpanded)
    }
}

private struct CategoryRowBody: View {
    let configuration: ButtonStyleConfiguration
    let isSelected: Bool
    let isExpanded: Bool
    @Environment(\.isFocused) private var isFocused

    var body: some View {
        ZStack(alignment: .leading) {
            configuration.label
                .font(isSelected ? AppFonts.bodyBold : AppFonts.body)
                .lineLimit(1)
                .foregroundStyle(foreground)
                .padding(.horizontal, Spacing.m)
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(height: CategorySidebar.rowHeight)
                .background(
                    RoundedRectangle(cornerRadius: Spacing.cornerRadius, style: .continuous)
                        .fill(isFocused ? AppColors.textPrimary : Color.clear)
                )
                .opacity(isExpanded ? 1 : 0)

            Capsule()
                .fill(isSelected ? AppColors.accent : AppColors.surfaceRaised)
                .frame(width: 6, height: isSelected ? 44 : 20)
                .padding(.leading, Spacing.xs)
                .opacity(isExpanded ? 0 : 1)
        }
        .scaleEffect(isFocused && isExpanded ? 1.04 : 1, anchor: .leading)
        .animation(.easeOut(duration: 0.15), value: isFocused)
    }

    private var foreground: Color {
        if isFocused { return AppColors.background }
        if isSelected { return AppColors.accent }
        return AppColors.textPrimary
    }
}
