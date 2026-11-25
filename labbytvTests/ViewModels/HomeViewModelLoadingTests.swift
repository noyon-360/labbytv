import Foundation
import Testing
@testable import labbytv

@MainActor
struct HomeViewModelLoadingTests {
    @Test func hasLoadedFlipsOnlyAfterFirstLoad() async {
        let defaults = UserDefaults(suiteName: "HomeViewModelLoadingTests")!
        defaults.removePersistentDomain(forName: "HomeViewModelLoadingTests")
        let viewModel = HomeViewModel(catalog: MockCatalogRepository(), history: MockWatchHistoryRepository(), preferences: Preferences(defaults: defaults))

        // Before the first fetch the view must show the spinner, not "Nothing to show yet".
        #expect(viewModel.hasLoaded == false)
        #expect(viewModel.isEmpty)

        await viewModel.load()

        #expect(viewModel.hasLoaded)
        #expect(viewModel.isLoading == false)
    }

    /// The sidebar TabView can cancel Home's `.task` mid-fetch. That must not
    /// count as "loaded with nothing", or the empty state replaces the spinner.
    @Test func cancelledLoadKeepsShowingLoader() async {
        let defaults = UserDefaults(suiteName: "HomeViewModelCancelTests")!
        defaults.removePersistentDomain(forName: "HomeViewModelCancelTests")
        let viewModel = HomeViewModel(catalog: MockCatalogRepository(), history: MockWatchHistoryRepository(), preferences: Preferences(defaults: defaults))

        let task = Task { await viewModel.load() }
        try? await Task.sleep(for: .milliseconds(50))
        task.cancel()
        await task.value

        #expect(viewModel.hasLoaded == false)
        #expect(viewModel.errorMessage == nil)
        #expect(viewModel.isLoading == false)

        // The next appearance retries and fills the shelves.
        await viewModel.load()
        #expect(viewModel.hasLoaded)
        #expect(!viewModel.movies.isEmpty)
    }
}
