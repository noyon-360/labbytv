import SwiftUI

/// Category list + lazily paged grid + loading/error/empty states, shared
/// by Live TV, Movies and Series.
///
/// Categories are a vertical list on the left (client reference app). The
/// list collapses to a thin rail while the grid has focus; swiping left from
/// the first column or pressing Back in the grid opens it again on the
/// selected category. The old horizontal chip bar sat above a grid that
/// draws outside its bounds, so scrolled cards slid over it. While the list
/// is open the grid slides right beside it.
struct CatalogGridView<Item: CatalogItem, Cell: View>: View {
    let viewModel: CatalogViewModel<Item>
    let columns: Int
    let emptySymbol: String
    @ViewBuilder let cell: (Item) -> Cell

    @FocusState private var focusedItem: Int?
    @FocusState private var focusedCategory: String?

    private var listExpanded: Bool { focusedItem == nil }

    var body: some View {
        ZStack(alignment: .topLeading) {
            VStack(alignment: .leading, spacing: Spacing.s) {
                Text(viewModel.selectedCategory.name.isEmpty ? "Untitled" : viewModel.selectedCategory.name)
                    .font(AppFonts.headline)
                    .foregroundStyle(AppColors.textPrimary)
                    .lineLimit(1)
                    // Only beside the open list: once the list collapses and
                    // the grid scrolls, cards would slide over it.
                    .opacity(listExpanded ? 1 : 0)
                content
            }
            .padding(.leading, CategorySidebar.collapsedWidth + Spacing.m)
            // Slide (not resize) the grid out from under the open list: a
            // card hidden under the list isn't "to the right" of it for the
            // focus engine, so Right from a category went nowhere.
            .offset(x: listExpanded ? CategorySidebar.slideOffset : 0)
            .animation(.easeInOut(duration: 0.25), value: listExpanded)

            CategorySidebar(
                categories: viewModel.categories,
                selected: viewModel.selectedCategory,
                isLocked: viewModel.isLocked,
                isExpanded: listExpanded,
                focusedCategory: $focusedCategory,
                onSelect: { category in Task { await viewModel.select(category) } }
            )
            .zIndex(1)
        }
        .task { await viewModel.loadIfNeeded() }
        .onChange(of: viewModel.parentalLockChangeCount) {
            Task { await viewModel.applyParentalLockChanges() }
        }
        .onChange(of: focusedCategory) { old, new in
            if let target = CategoryFocusRule.redirect(from: old, to: new, selected: viewModel.selectedCategory.id) {
                focusedCategory = target
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading && viewModel.items.isEmpty {
            LoadingView()
        } else if let message = viewModel.errorMessage, viewModel.items.isEmpty {
            ErrorView(message: message, retry: { Task { await viewModel.retry() } })
        } else if viewModel.items.isEmpty {
            if viewModel.selectedCategory == .favorites {
                EmptyStateView(symbol: "heart", title: "No favourite channels yet", message: "Press and hold Select on a channel, or use the heart in the player.")
            } else {
                EmptyStateView(symbol: emptySymbol, title: "Nothing here yet", message: "Try another category.")
            }
        } else {
            ScrollView {
                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: Spacing.gridSpacing, alignment: .top), count: columns),
                    spacing: Spacing.xl
                ) {
                    ForEach(viewModel.items) { item in
                        cell(item)
                            .focused($focusedItem, equals: item.id)
                            .onAppear { Task { await viewModel.loadMoreIfNeeded(after: item) } }
                    }
                }
                .padding(.vertical, Spacing.m)

                if viewModel.isLoadingMore {
                    ProgressView().padding(Spacing.l)
                }
            }
            .scrollClipDisabled()
            .focusSection()
            // Only while the grid has focus; on the list, Back keeps its
            // normal job (open the app sidebar / leave the app).
            .onExitCommand(perform: focusedItem == nil ? nil : {
                focusedCategory = viewModel.selectedCategory.id
            })
        }
    }
}
