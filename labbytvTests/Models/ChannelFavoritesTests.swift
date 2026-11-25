import Foundation
import Testing
@testable import labbytv

struct ChannelFavoritesTests {
    @Test func keepsOnlyLovedLiveChannelsOnce() throws {
        let json = """
        [
          {"_id": "1", "videoId": "101", "videoType": "live", "title": "News", "thumbnail": "http://x/n.png", "isLoved": true},
          {"_id": "2", "videoId": "55", "videoType": "movie", "title": "Film", "isLoved": true},
          {"_id": "3", "videoId": "101", "videoType": "live", "title": "News again", "isLoved": true},
          {"_id": "4", "videoId": "202", "videoType": "LIVE", "title": "Sports", "isLoved": true},
          {"_id": "5", "videoId": "303", "videoType": "live", "title": "Old", "isLoved": false}
        ]
        """
        let items = try JSONDecoder().decode([WatchHistoryItem].self, from: Data(json.utf8))
        let channels = ChannelFavorites.channels(from: items)
        #expect(channels.map(\.id) == [101, 202])
        #expect(channels.first?.name == "News")
    }
}
