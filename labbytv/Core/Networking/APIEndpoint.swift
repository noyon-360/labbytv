import Foundation

/// Every backend path, mirroring `api_constants.dart` in the Flutter app.
nonisolated struct APIEndpoint: Sendable, Equatable {
    let path: String
    /// Public endpoints (login, refresh) must not trigger a token refresh on
    /// 401/403: the backend answers a wrong password with 403.
    var requiresAuth: Bool = true

    static let production = URL(string: "https://api.labbytv.com/api/v1")!

    /// Debug builds can point at a local backend with the launch argument
    /// `-LabbyAPIBase http://127.0.0.1:5000/api/v1`. Release builds always
    /// use production.
    static var baseURL: URL {
        #if DEBUG
        if let override = UserDefaults.standard.string(forKey: "LabbyAPIBase"),
           let url = URL(string: override), url.scheme != nil {
            return url
        }
        #endif
        return production
    }

    // MARK: Auth
    static let login = APIEndpoint(path: "/auth/login", requiresAuth: false)
    static let register = APIEndpoint(path: "/auth/register", requiresAuth: false)
    static let refreshToken = APIEndpoint(path: "/auth/refresh-token", requiresAuth: false)
    /// Emails a 6-digit OTP.
    static let forgotPassword = APIEndpoint(path: "/auth/forget", requiresAuth: false)
    static let resetPassword = APIEndpoint(path: "/auth/reset-password", requiresAuth: false)
    static let tvCode = APIEndpoint(path: "/auth/tv/code", requiresAuth: false)
    static let tvPoll = APIEndpoint(path: "/auth/tv/poll", requiresAuth: false)

    // MARK: User
    static let profile = APIEndpoint(path: "/user/profile")
    /// Parental lock "Forgot PIN?": `{ password }` → `{ valid }`. Answers 200
    /// even for a wrong password, because a 401 would log the user out.
    static let verifyPassword = APIEndpoint(path: "/user/verify-password")

    // MARK: Viewer profiles ("Who's Watching")
    static let viewerProfiles = APIEndpoint(path: "/profiles")
    static func viewerProfile(_ id: String) -> APIEndpoint {
        APIEndpoint(path: "/profiles/\(id)")
    }

    // MARK: Playlist
    static let addPlaylist = APIEndpoint(path: "/playlist/add-playlist")
    static let getPlaylists = APIEndpoint(path: "/playlist/get-playlist")

    // MARK: Server (Xtream proxy)
    static let connectTV = APIEndpoint(path: "/server/connect-tv")
    static let playURL = APIEndpoint(path: "/server/get-play-url")

    // MARK: Categories
    static let categories = APIEndpoint(path: "/category")
    static func categoryItems(_ id: String) -> APIEndpoint {
        APIEndpoint(path: "/category/\(id)")
    }

    // MARK: EPG
    static let epgSchedule = APIEndpoint(path: "/epg/schedule")

    // MARK: Watch history
    static let updateVideoStatus = APIEndpoint(path: "/watch-history/update")
    static let watchHistory = APIEndpoint(path: "/watch-history/history")
    static let favorites = APIEndpoint(path: "/watch-history/favorites")
    static func videoStatus(_ videoId: String) -> APIEndpoint {
        APIEndpoint(path: "/watch-history/status/\(videoId)")
    }

    // MARK: Payment
    static let mySubscription = APIEndpoint(path: "/payment/my-subscription")
    static let verifyApplePurchase = APIEndpoint(path: "/payment/verify-apple-purchase")
}
