import Foundation
import Observation

/// Profile → Parental Lock: set / change / remove the PIN and pick which
/// categories are locked. Mirrors Flutter `ParentalLockScreen`.
@MainActor
@Observable
final class ParentalLockViewModel {
    let lock: ParentalLockService
    private(set) var section: ContentType = .channels
    var query = ""
    private(set) var categories: [ContentType: [Category]] = [:]
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    @ObservationIgnored private let catalog: any CatalogRepository

    init(lock: ParentalLockService, catalog: any CatalogRepository) {
        self.lock = lock
        self.catalog = catalog
    }

    var hasPin: Bool { lock.hasPin }

    /// The current section's categories matching the search text.
    var visibleCategories: [Category] {
        Self.filter(categories[section] ?? [], query: query)
    }

    var hasLoadedSection: Bool { categories[section] != nil }

    func isLocked(_ category: Category) -> Bool {
        lock.isCategoryLocked(section, categoryID: category.id)
    }

    func toggle(_ category: Category) {
        lock.setCategoryLocked(section, categoryID: category.id, locked: !isLocked(category))
    }

    func select(_ newSection: ContentType) async {
        guard newSection != section else { return }
        section = newSection
        errorMessage = nil
        await loadIfNeeded()
    }

    func loadIfNeeded() async {
        guard categories[section] == nil, !isLoading else { return }
        let current = section
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            categories[current] = try await catalog.categories(for: current)
        } catch is CancellationError {
            return
        } catch {
            guard current == section else { return }
            errorMessage = (error as? APIError)?.userMessage ?? APIError.unknown.userMessage
        }
    }

    func setOrChangePin() async {
        _ = await lock.chooseNewPin()
    }

    func turnOff() {
        lock.removePin()
    }

    /// Case-insensitive name match; "All" (empty id) is never listed.
    nonisolated static func filter(_ categories: [Category], query: String) -> [Category] {
        let text = query.trimmingCharacters(in: .whitespacesAndNewlines)
        return categories.filter { category in
            !category.id.isEmpty && (text.isEmpty || category.name.localizedCaseInsensitiveContains(text))
        }
    }
}
