import SwiftUI

/// Vertical category list on the left of Live TV, Movies and Series (the
/// layout of the client's reference app). It collapses to a thin rail while
/// the grid has focus; while open, the content beside it slides right
/// (never resizes, never sits under the list).
struct CategorySidebar: View {
    let categories: [Category]
    let selected: Category
    var isLocked: (Category) -> Bool = { _ in false }
    let isExpanded: Bool
    let focusedCategory: FocusState<String?>.Binding
    let onSelect: (Category) -> Void

    static let rowHeight: CGFloat = 66
    static let expandedWidth: CGFloat = 440
    static let collapsedWidth: CGFloat = 32
    /// How far content beside the list moves while it's open.
    static let slideOffset: CGFloat = expandedWidth - collapsedWidth + 16

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical) {
                // Not lazy: Back has to focus the selected row even when it's
                // far down the list, and a lazy row that was never built
                // can't take focus. Lists are a few hundred rows at most.
                VStack(alignment: .leading, spacing: 4) {
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
                        .buttonStyle(CategoryRowButtonStyle(isSelected: category == selected, isExpanded: isExpanded))
                        .focused(focusedCategory, equals: category.id)
                        .id(category.id)
                    }
                }
                .padding(.vertical, Spacing.s)
            }
            .scrollIndicators(.hidden)
            .scrollClipDisabled()
            .onAppear { proxy.scrollTo(selected.id, anchor: .center) }
            .onChange(of: selected) { proxy.scrollTo(selected.id, anchor: .center) }
        }
        .frame(width: isExpanded ? Self.expandedWidth : Self.collapsedWidth, alignment: .leading)
        .background(alignment: .leading) {
            // Fades the grid out under the open list instead of a hard edge.
            LinearGradient(
                stops: [
                    .init(color: AppColors.background, location: 0),
                    .init(color: AppColors.background, location: 0.7),
                    .init(color: AppColors.background.opacity(0), location: 1),
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: Self.expandedWidth + Spacing.xxl)
            .opacity(isExpanded ? 1 : 0)
            .allowsHitTesting(false)
        }
        .focusSection()
        .animation(.easeInOut(duration: 0.25), value: isExpanded)
    }
}

#if DEBUG
private struct CategorySidebarPreview: View {
    @FocusState private var focused: String?
    let expanded: Bool

    var body: some View {
        CategorySidebar(
            categories: [.all, Category(id: "1", name: "USA | NEWS"), Category(id: "2", name: "USA | SPORTS"), Category(id: "3", name: "Kids")],
            selected: Category(id: "1", name: "USA | NEWS"),
            isLocked: { $0.id == "3" },
            isExpanded: expanded,
            focusedCategory: $focused,
            onSelect: { _ in }
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(AppColors.surface)
    }
}

#Preview("Expanded") { CategorySidebarPreview(expanded: true) }
#Preview("Collapsed") { CategorySidebarPreview(expanded: false) }
#endif
