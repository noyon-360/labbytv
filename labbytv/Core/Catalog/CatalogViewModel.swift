import Foundation
import Observation

/// Category chips + paged grid, shared by Live TV, Movies and Series.
/// Mirrors the Flutter `LiveTvController` / `MovieController` paging:
/// a generation counter drops stale responses, and load-more de-duplicates
/// because Xtream's ordering isn't stable between pages.
@MainActor
@Observable
final class CatalogViewModel<Item: CatalogItem> {
    let type: ContentType
    let pageSize: Int

    private(set) var categories: [Category] = [.all]
    private(set) var selectedCategory: Category = .all
    private(set) var items: [Item] = []
    private(set) var isLoading = false
    private(set) var isLoadingMore = false
    private(set) var hasMore = true
    private(set) var errorMessage: String?

    @ObservationIgnored private let repository: any CatalogRepository
    @ObservationIgnored private let parentalLock: ParentalLockService?
    @ObservationIgnored private var nextPage = 1
    @ObservationIgnored private var generation = 0
    @ObservationIgnored private var seenLockChange = 0
    @ObservationIgnored private var seenLockReveal = 0

    /// When "All" is mostly locked, a page can filter down to nothing; fetch a
    /// few more pages before showing the empty state.
    private static var maxEmptyPageSkips: Int { 5 }

    init(type: ContentType, repository: any CatalogRepository, parentalLock: ParentalLockService? = nil, pageSize: Int = 48) {
        self.type = type
        self.repository = repository
        self.parentalLock = parentalLock
        self.pageSize = pageSize
        seenLockChange = parentalLock?.changeCount ?? 0
        seenLockReveal = parentalLock?.revealCount ?? 0
    }

    /// Observed by the view so lock changes apply while the grid is on screen.
    var parentalLockChangeCount: Int { parentalLock?.changeCount ?? 0 }

    /// Shows a lock on chips the PIN hasn't opened this session.
    func isLocked(_ category: Category) -> Bool {
        parentalLock?.isHidden(type, categoryID: category.id) ?? false
    }

    /// Returning to the tab keeps what was loaded. If the first load was
    /// cancelled (view left early), the next appearance tries again.
    func loadIfNeeded() async {
        await applyParentalLockChanges()
        guard items.isEmpty, !isLoading else { return }
        async let categoriesTask: Void = loadCategories()
        async let itemsTask: Void = reload()
        _ = await (categoriesTask, itemsTask)
    }

    func select(_ category: Category) async {
        guard category != selectedCategory || errorMessage != nil else { return }
        guard await parentalLock?.guardCategory(type, categoryID: category.id) ?? true else { return }
        // The reload below filters with the current locks.
        markLockChangesSeen()
        selectedCategory = category
        await reload()
    }

    func retry() async {
        if categories.count <= 1 {
            await loadCategories()
        }
        await reload()
    }

    /// Call from each cell's `onAppear`; loads the next page near the end.
    func loadMoreIfNeeded(after item: Item) async {
        guard hasMore, !isLoading, !isLoadingMore else { return }
        guard let index = items.firstIndex(where: { $0.id == item.id }),
              index >= items.count - 8 else { return }
        await loadMore()
    }

    func reload() async {
        generation += 1
        let current = generation
        nextPage = 1
        hasMore = true
        isLoading = true
        errorMessage = nil
        items = []

        do {
            var page: [Item] = try await fetch(page: 1)
            guard current == generation else { return }
            hasMore = page.count >= pageSize
            nextPage = 2
            items = Self.merge(existing: [], incoming: visible(page))
            var skips = 0
            while items.isEmpty, hasMore, skips < Self.maxEmptyPageSkips {
                skips += 1
                page = try await fetch(page: nextPage)
                guard current == generation else { return }
                hasMore = page.count >= pageSize
                nextPage += 1
                items = Self.merge(existing: items, incoming: visible(page))
            }
        } catch is CancellationError {
            // A newer load or the view disappearing cancelled this one.
        } catch {
            guard current == generation else { return }
            if items.isEmpty {
                errorMessage = (error as? APIError)?.userMessage ?? APIError.unknown.userMessage
            }
        }
        if current == generation {
            isLoading = false
        }
    }

    /// Applies parental-lock changes made since the last call: leave a
    /// category that just got locked, drop newly locked items, or reload when
    /// something was revealed (filtered-out items can't come back without a fetch).
    func applyParentalLockChanges() async {
        guard let parentalLock, parentalLock.changeCount != seenLockChange else { return }
        let reveals = parentalLock.revealCount != seenLockReveal
        markLockChangesSeen()
        // Never loaded yet: the first load filters anyway.
        guard !items.isEmpty || isLoading || errorMessage != nil else { return }

        if parentalLock.isHidden(type, categoryID: selectedCategory.id) {
            selectedCategory = .all
            await reload()
        } else if reveals {
            await reload()
        } else {
            items = visible(items)
        }
    }

    private func markLockChangesSeen() {
        seenLockChange = parentalLock?.changeCount ?? 0
        seenLockReveal = parentalLock?.revealCount ?? 0
    }

    private func visible(_ list: [Item]) -> [Item] {
        guard let parentalLock else { return list }
        return list.filter { !parentalLock.isHidden(type, categoryID: $0.categoryId) }
    }

    private func loadMore() async {
        let current = generation
        isLoadingMore = true
        defer { if current == generation { isLoadingMore = false } }
        do {
            let page: [Item] = try await fetch(page: nextPage)
            guard current == generation else { return }
            // Paging follows the raw page size, not what's left after filtering.
            items = Self.merge(existing: items, incoming: visible(page))
            hasMore = page.count >= pageSize
            nextPage += 1
        } catch {
            // Keep what's shown; scrolling back to the end retries.
        }
    }

    private func loadCategories() async {
        do {
            let list = try await repository.categories(for: type)
            categories = [.all] + list
        } catch {
            // Chips are optional: the "All" grid still works without them.
        }
    }

    private func fetch(page: Int) async throws -> [Item] {
        try await repository.items(
            type,
            categoryID: selectedCategory.id.isEmpty ? nil : selectedCategory.id,
            search: nil,
            page: page,
            limit: pageSize
        )
    }

    /// Appends `incoming`, dropping ids already shown (and duplicates within the page).
    nonisolated static func merge(existing: [Item], incoming: [Item]) -> [Item] {
        var seen = Set(existing.map(\.id))
        var result = existing
        for item in incoming where seen.insert(item.id).inserted {
            result.append(item)
        }
        return result
    }
}
