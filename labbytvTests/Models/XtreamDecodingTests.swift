import Foundation
import Testing
@testable import labbytv

struct XtreamDecodingTests {
    @Test func channelAcceptsStringOrNumberIDs() throws {
        let json = #"[{"stream_id":"12","name":"A","num":1},{"stream_id":13,"name":"B","category_id":5},{"name":null,"stream_id":{}}]"#
        let list = try JSONDecoder().decode(LossyArray<Channel>.self, from: Data(json.utf8)).elements
        #expect(list.map(\.id) == [12, 13, 0])
        #expect(list[1].categoryId == "5")
    }

    @Test func seriesInfoAcceptsSeasonsAsMapAndSortsEpisodes() throws {
        let json = #"""
        {"info":{"name":"S"},"seasons":{"0":{"season_number":"2","name":"Two"}},
         "episodes":{"2":[{"id":"9","episode_num":"2","season":2},{"id":"8","episode_num":1,"season":2}]}}
        """#
        let info = try JSONDecoder().decode(SeriesInfo.self, from: Data(json.utf8))
        #expect(info.seasons.first?.seasonNumber == 2)
        #expect(info.episodes[2]?.map(\.id) == ["8", "9"])
        #expect(info.playableSeasons.map(\.name) == ["Two"])
    }

    @Test func seriesInfoWithEmptyPHPCollections() throws {
        let json = #"{"info":[],"seasons":{},"episodes":[]}"#
        let info = try JSONDecoder().decode(SeriesInfo.self, from: Data(json.utf8))
        #expect(info.seasons.isEmpty)
        #expect(info.playableSeasons.isEmpty)
    }
}
