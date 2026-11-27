import Foundation
import Testing
@testable import labbytv

/// Home rows, category badges and My List (client doc "Android TV V1",
/// brought to Apple TV).
struct HomeRowsTests {
    private func history(_ json: String) throws -> [WatchHistoryItem] {
        try JSONDecoder().decode([WatchHistoryItem].self, from: Data(json.utf8))
    }

    @Test func decodesCategoryAndWatchedTime() throws {
        let items = try history("""
        [{"_id":"1","videoId":"7","videoType":"movie","title":"A","categoryName":" Action ","lastWatchedAt":"2026-11-27T09:30:00.123Z"},
         {"_id":"2","videoId":"8","videoType":"live","title":"B","categoryName":"","updatedAt":"2026-11-26T09:30:00Z"},
         {"_id":"3","videoId":"9","videoType":"movie","title":"C"}]
        """)
        #expect(items[0].categoryName == "Action")
        #expect(abs((items[0].lastWatchedAt?.timeIntervalSince1970 ?? 0) - 1_795_771_800.123) < 0.001)
        #expect(items[1].categoryName == nil)
        #expect(items[1].lastWatchedAt == Date(timeIntervalSince1970: 1_795_685_400))
        #expect(items[2].categoryName == nil)
        #expect(items[2].lastWatchedAt == nil)
    }

    @Test func recentlyWatchedIsNewestFirstOnceEachChannelsIncluded() throws {
        let items = try history("""
        [{"_id":"1","videoId":"7","videoType":"movie","title":"Old film","lastWatchedAt":"2026-11-20T00:00:00Z"},
         {"_id":"2","videoId":"3","videoType":"live","title":"News","lastWatchedAt":"2026-11-27T00:00:00Z"},
         {"_id":"3","videoId":"7","videoType":"movie","title":"Old film again","lastWatchedAt":"2026-11-19T00:00:00Z"},
         {"_id":"4","videoId":"3","videoType":"movie","title":"Same id, other type","lastWatchedAt":"2026-11-21T00:00:00Z"},
         {"_id":"5","videoId":"99","videoType":"movie","title":"No date"}]
        """)
        #expect(HomeRows.recentlyWatched(items).map(\.id) == ["2", "4", "1", "5"])
        #expect(HomeRows.recentlyWatched(items, limit: 2).map(\.id) == ["2", "4"])
    }

    @Test func recentlyAddedSortsByDateAndHidesWithoutDates() {
        let movies = [
            Movie(id: 1, name: "a", added: 100),
            Movie(id: 2, name: "b", added: nil),
            Movie(id: 3, name: "c", added: 300),
            Movie(id: 4, name: "d", added: 300),
        ]
        #expect(HomeRows.recentlyAdded(movies) { $0.added }.map(\.id) == [3, 4, 1, 2])
        #expect(HomeRows.recentlyAdded(movies, limit: 1) { $0.added }.map(\.id) == [3])
        let undated = [Movie(id: 1, name: "a"), Movie(id: 2, name: "b", added: 0)]
        #expect(HomeRows.recentlyAdded(undated) { $0.added }.isEmpty)
    }

    @Test func decodesProviderAddedTimes() throws {
        let movie = try JSONDecoder().decode(Movie.self, from: Data(#"{"stream_id":5,"name":"M","added":"1700000000"}"#.utf8))
        let series = try JSONDecoder().decode(Series.self, from: Data(#"{"series_id":6,"name":"S","last_modified":1700000001}"#.utf8))
        #expect(movie.added == 1_700_000_000)
        #expect(series.lastModified == 1_700_000_001)
    }

    @Test func captionPrefersCategory() throws {
        let items = try history("""
        [{"_id":"1","videoId":"7","videoType":"movie","title":"A","categoryName":"Action"},
         {"_id":"2","videoId":"8","videoType":"live","title":"B"},
         {"_id":"3","videoId":"9","videoType":"series","title":"C","seasonNumber":2,"episodeNumber":4,"categoryName":"Drama"},
         {"_id":"4","videoId":"10","videoType":"series","title":"D","seasonNumber":1,"episodeNumber":1},
         {"_id":"5","videoId":"11","videoType":"movie","title":"E"}]
        """)
        #expect(items.map(HomeRows.caption(for:)) == ["Action", "Live TV", "S2 E4 · Drama", "S1 E1", "Movie"])
    }

    @Test func ratingBadge() {
        #expect(RatingBadge.text(0) == nil)
        #expect(RatingBadge.text(4.25) == "★ 4.2")
        #expect(RatingBadge.text(7) == "★ 5.0")
    }
}

struct WatchLaterDecodingTests {
    @Test func decodesListAndRoutes() throws {
        let json = """
        {"items":[{"_id":"w1","videoType":"movie","videoId":"55","title":"Film","thumbnail":"http://x/p.jpg","playlist":{"_id":"p","name":"Main"}},
                  {"_id":"w2","videoType":"series","videoId":"66","title":"Show","playlist":"p"},
                  {"_id":"w3","videoType":"movie","videoId":"not-a-number","title":"Broken"}],
         "pagination":{"currentPage":1,"totalPages":1,"totalItems":3}}
        """
        let page = try JSONDecoder().decode(WatchLaterPage.self, from: Data(json.utf8))
        #expect(page.items.map(\.id) == ["w1", "w2", "w3"])
        #expect(page.items[0].route == .movie(Movie(id: 55, name: "Film", streamIcon: "http://x/p.jpg")))
        #expect(page.items[1].route == .series(Series(id: 66, name: "Show")))
        #expect(page.items[2].route == nil)
    }

    @Test func decodesStatus() throws {
        let saved = try JSONDecoder().decode(WatchLaterStatus.self, from: Data(#"{"isSaved":true,"id":"w1"}"#.utf8))
        let notSaved = try JSONDecoder().decode(WatchLaterStatus.self, from: Data(#"{"isSaved":false,"id":null}"#.utf8))
        #expect(saved.isSaved && saved.id == "w1")
        #expect(!notSaved.isSaved && notSaved.id == nil)
    }

    @Test func addBodyMatchesFlutter() throws {
        let body = AddWatchLaterRequest(playlistId: "p", videoType: "movie", videoId: "55", title: "Film", thumbnail: nil)
        let object = try JSONSerialization.jsonObject(with: JSONEncoder().encode(body)) as? [String: String]
        #expect(object == ["playlistId": "p", "videoType": "movie", "videoId": "55", "title": "Film"])
    }
}

@MainActor
struct MyListToggleTests {
    @Test func addThenRemove() async {
        let list = MyList(repository: MockWatchLaterRepository(items: []))
        let toggle = MyListToggleViewModel(myList: list, videoType: "movie", videoID: "55")
        await toggle.load()
        #expect(toggle.isKnown && !toggle.isSaved)

        await toggle.toggle(title: "Film", thumbnail: "")
        #expect(toggle.isSaved)
        #expect(list.items.map(\.videoId) == ["55"])

        await toggle.toggle(title: "Film", thumbnail: "")
        #expect(!toggle.isSaved)
        #expect(list.items.isEmpty)
    }

    @Test func failedAddRollsBack() async {
        let list = MyList(repository: FailingWatchLaterRepository())
        let toggle = MyListToggleViewModel(myList: list, videoType: "series", videoID: "66")
        await toggle.toggle(title: "Show", thumbnail: "")
        #expect(!toggle.isSaved)
        #expect(list.items.isEmpty)
    }

    @Test func statusUsesLoadedListFirst() async {
        let list = MyList(repository: MockWatchLaterRepository(items: [WatchLaterItem(id: "w9", videoType: "movie", videoId: "55", title: "Film")]))
        await list.loadIfNeeded()
        let status = await list.status(videoType: "movie", videoID: "55")
        #expect(status?.isSaved == true && status?.id == "w9")
        let other = await list.status(videoType: "series", videoID: "55")
        #expect(other?.isSaved == false)
    }
}

private struct FailingWatchLaterRepository: WatchLaterRepository {
    func list(page: Int, limit: Int) async throws -> [WatchLaterItem] { throw APIError.timeout }
    func status(videoType: String, videoID: String) async throws -> WatchLaterStatus { throw APIError.timeout }
    func add(videoType: String, videoID: String, title: String, thumbnail: String?) async throws -> WatchLaterItem { throw APIError.timeout }
    func remove(id: String) async throws { throw APIError.timeout }
}

struct VideoResolutionTests {
    @Test func labelsMatchAndroid() {
        #expect(VideoResolution.label(for: .zero) == nil)
        #expect(VideoResolution.label(for: CGSize(width: 640, height: 360)) == "SD")
        #expect(VideoResolution.label(for: CGSize(width: 1280, height: 720)) == "HD")
        #expect(VideoResolution.label(for: CGSize(width: 1920, height: 1080)) == "FHD")
        #expect(VideoResolution.label(for: CGSize(width: 1920, height: 800)) == "FHD")
        #expect(VideoResolution.label(for: CGSize(width: 3840, height: 2160)) == "4K")
    }
}
