import SwiftUI

/// Horizontal chip bar. A focus section, so swiping down from any chip
/// lands in the grid and swiping up from the grid returns here.
struct CategoryChips: View {
    let categories: [Category]
    let selected: Category
    /// Parental lock: chips that need the PIN show a lock.
    var isLocked: (Category) -> Bool = { _ in false }
    let onSelect: (Category) -> Void

    var body: some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: Spacing.s) {
                ForEach(categories) { category in
                    Button {
                        onSelect(category)
                    } label: {
                        HStack(spacing: Spacing.xs) {
                            if isLocked(category) {
                                Image(systemName: "lock.fill")
                            }
                            Text(category.name.isEmpty ? "Untitled" : category.name)
                        }
                    }
                    .buttonStyle(ChipButtonStyle(isSelected: category == selected))
                }
            }
            .padding(.vertical, Spacing.s)
        }
        // A LazyHStack is vertically greedy, so without this the bar
        // swallows all spare height and floats the chips mid-screen.
        .fixedSize(horizontal: false, vertical: true)
        .scrollClipDisabled()
        .focusSection()
    }
}

#Preview {
    CategoryChips(
        categories: [.all, Category(id: "1", name: "Sports"), Category(id: "2", name: "News")],
        selected: .all,
        isLocked: { $0.id == "2" },
        onSelect: { _ in }
    )
    .padding()
    .background(AppColors.background)
}
