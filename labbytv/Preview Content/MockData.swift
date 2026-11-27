#if DEBUG
import Foundation

nonisolated enum MockData {
    /// One main profile, so the mock run opens straight into the app (as a
    /// real single-profile account does).
    static let viewerProfiles = [
        ViewerProfile(id: "profile-main", name: "Preview User", avatar: "avatar_01", isDefault: true),
    ]

    /// For previews of "Who's Watching".
    static let severalViewerProfiles = viewerProfiles + [
        ViewerProfile(id: "profile-kids", name: "Kids", avatar: "avatar_05"),
        ViewerProfile(id: "profile-guest", name: "Guest", avatar: "avatar_09"),
    ]

    static let user = User(
        id: "preview-user",
        name: "Preview User",
        email: "preview@example.com",
        role: "user",
        plan: "free",
        subscriptionStatus: nil,
        isEmailVerified: true,
        subscriptionExpiresAt: nil
    )

    /// LABBY TV Pro, for the UI-test mock mode (the Guide is Pro-only).
    static let premiumUser = User(
        id: "preview-user",
        name: "Preview User",
        email: "preview@example.com",
        role: "user",
        plan: "premium",
        subscriptionStatus: "active",
        isEmailVerified: true,
        subscriptionExpiresAt: nil
    )

    static let loginResponse = LoginResponse(
        accessToken: "preview-access-token",
        refreshToken: "preview-refresh-token",
        role: "user",
        id: "preview-user",
        user: user
    )

    static let playlists = [
        Playlist(id: "p1", name: "Home Provider", url: "http://example.com:8080", userName: "demo", password: "demo"),
        Playlist(id: "p2", name: "Backup", url: "http://backup.example.com", userName: "demo", password: "demo"),
    ]

    static let categories = [
        Category(id: "1", name: "News"),
        Category(id: "2", name: "Sports"),
        Category(id: "3", name: "Movies"),
        Category(id: "4", name: "Kids"),
    ]

    static let channels: [Channel] = (1...24).map {
        Channel(id: $0, num: $0, name: ["News 24", "Sports One", "Cinema HD", "Kids Fun", "Music Live", "Docs"][$0 % 6] + " \($0)", categoryId: String($0 % 4 + 1))
    }

    static let movies: [Movie] = (1...24).map {
        Movie(id: 100 + $0, name: ["The Long Night", "Harbor Lights", "Red Canyon", "Paper Moon City"][$0 % 4] + " \($0)", rating: "7.\($0 % 9)", rating5Based: 3.5, categoryId: String($0 % 4 + 1), added: 1_700_000_000 + $0 * 86_400)
    }

    static let series: [Series] = (1...24).map {
        Series(id: 500 + $0, name: ["Northern Line", "The Archive", "Signal Lost"][$0 % 3] + " \($0)", plot: "A gripping story.", genre: "Drama", releaseDate: "2023", rating5Based: 4.1, categoryId: String($0 % 4 + 1), lastModified: 1_700_000_000 + (24 - $0) * 86_400)
    }

    static let programs: [EPGProgram] = {
        let start = DateFormatting.floorToHalfHour(.now).addingTimeInterval(-1800)
        return (0..<8).map { index in
            EPGProgram(
                id: "\(index)",
                title: ["Morning News", "Live Match", "Documentary", "Talk Show"][index % 4],
                description: "Programme description goes here.",
                start: start.addingTimeInterval(Double(index) * 2700),
                end: start.addingTimeInterval(Double(index + 1) * 2700)
            )
        }
    }()

    static let historyItems: [WatchHistoryItem] = decode("""
    [
      {"_id":"h1","videoId":"101","videoType":"movie","title":"The Long Night 1","currentTime":1200,"duration":5400,"isCompleted":false,"isLoved":true,"categoryName":"Action","lastWatchedAt":"2026-11-27T09:00:00.000Z"},
      {"_id":"h2","videoId":"102","videoType":"movie","title":"Harbor Lights 2","currentTime":300,"duration":6000,"isCompleted":false,"isLoved":false,"categoryName":"Drama","lastWatchedAt":"2026-11-27T10:00:00.000Z"},
      {"_id":"h3","videoId":"3","videoType":"live","title":"Cinema HD 3","isLoved":true,"categoryName":"Movies","lastWatchedAt":"2026-11-27T08:00:00.000Z"},
      {"_id":"h4","videoId":"5","videoType":"live","title":"Music Live 5","isLoved":true,"categoryName":"Sports","lastWatchedAt":"2026-11-26T08:00:00.000Z"}
    ]
    """)

    static let watchLaterItems: [WatchLaterItem] = [
        WatchLaterItem(id: "w1", videoType: "movie", videoId: "105", title: "Harbor Lights 5"),
        WatchLaterItem(id: "w2", videoType: "series", videoId: "502", title: "Signal Lost 2"),
    ]

    static let seriesInfo: SeriesInfo = decode("""
    {
      "info": {"name":"Northern Line","plot":"A detective returns to her hometown.","cast":"Ann Lee, Tom Hart","genre":"Drama","releaseDate":"2023"},
      "seasons": [{"season_number":1,"name":"Season 1"},{"season_number":2,"name":"Season 2"}],
      "episodes": {
        "1": [{"id":"9001","episode_num":1,"title":"Pilot","season":1,"container_extension":"mp4","info":{"duration":"00:52:10"}},
              {"id":"9002","episode_num":2,"title":"The Return","season":1,"container_extension":"mp4","info":{"duration":"00:49:30"}}],
        "2": [{"id":"9101","episode_num":1,"title":"New Blood","season":2,"container_extension":"mkv"}]
      }
    }
    """)

    static let movieInfo: MovieInfo = decode("""
    {"info":{"name":"The Long Night","plot":"A city loses power for a week.","genre":"Thriller","releasedate":"2022-05-01","duration_secs":6120,"director":"J. Moss","cast":"Ann Lee, Tom Hart","rating":7.4},
     "movie_data":{"stream_id":101,"container_extension":"mp4"}}
    """)

    private static func decode<T: Decodable>(_ json: String) -> T {
        // Force-try is fine for fixed preview fixtures.
        try! JSONDecoder().decode(T.self, from: Data(json.utf8))
    }
}
#endif
