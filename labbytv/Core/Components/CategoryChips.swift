import SwiftUI

/// Horizontal chip bar. A focus section, so swiping down from any chip
/// lands in the grid and swiping up from the grid returns here.
struct CategoryChips: View {
    let categories: [Category]
    let selected: Category
    let onSelect: (Category) -> Void

    var body: some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: Spacing.s) {
                ForEach(categories) { category in
                    Button(category.name.isEmpty ? "Untitled" : category.name) {
                        onSelect(category)
                    }
                    .buttonStyle(ChipButtonStyle(isSelected: category == selected))
                }
            }
            .padding(.vertical, Spacing.s)
        }
        .scrollClipDisabled()
        .focusSection()
    }
}

#Preview {
    CategoryChips(
        categories: [.all, Category(id: "1", name: "Sports"), Category(id: "2", name: "News")],
        selected: .all,
        onSelect: { _ in }
    )
    .padding()
    .background(AppColors.background)
}
