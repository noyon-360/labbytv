import SwiftUI

/// Chips + lazily paged grid + loading/error/empty states, shared by
/// Live TV, Movies and Series.
struct CatalogGridView<Item: CatalogItem, Cell: View>: View {
    let viewModel: CatalogViewModel<Item>
    let columns: Int
    let emptySymbol: String
    @ViewBuilder let cell: (Item) -> Cell

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            CategoryChips(
                categories: viewModel.categories,
                selected: viewModel.selectedCategory,
                isLocked: viewModel.isLocked,
                onSelect: { category in Task { await viewModel.select(category) } }
            )

            content
        }
        .task { await viewModel.loadIfNeeded() }
        .onChange(of: viewModel.parentalLockChangeCount) {
            Task { await viewModel.applyParentalLockChanges() }
        }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading && viewModel.items.isEmpty {
            LoadingView()
        } else if let message = viewModel.errorMessage, viewModel.items.isEmpty {
            ErrorView(message: message, retry: { Task { await viewModel.retry() } })
        } else if viewModel.items.isEmpty {
            EmptyStateView(symbol: emptySymbol, title: "Nothing here yet", message: "Try another category.")
        } else {
            ScrollView {
                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: Spacing.gridSpacing, alignment: .top), count: columns),
                    spacing: Spacing.xl
                ) {
                    ForEach(viewModel.items) { item in
                        cell(item)
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
        }
    }
}
