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
}
