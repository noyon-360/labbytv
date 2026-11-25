import Testing
@testable import labbytv

struct RelatedTitlesTests {
    private func movie(_ id: Int) -> Movie { Movie(id: id, name: "M\(id)") }

    @Test func dropsTheCurrentTitleAndDuplicates() {
        let picked = RelatedTitles.pick([movie(1), movie(2), movie(2), movie(3)], excluding: 1)
        #expect(picked.map(\.id) == [2, 3])
    }

    @Test func capsTheShelf() {
        #expect(RelatedTitles.pick((1...40).map(movie), excluding: 99, limit: 20).count == 20)
    }

    @Test func unknownCategoryLoadsNothing() async {
        let items: [Movie] = await RelatedTitles.load(.movies, categoryID: "", excluding: 1, catalog: MockCatalogRepository())
        #expect(items.isEmpty)
    }
}
