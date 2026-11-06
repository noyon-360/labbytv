import AVFoundation
import AVKit
import Foundation
import Observation
import os
#if canImport(LabbyVLC)
import LabbyVLC
#endif

@MainActor
@Observable
final class PlayerViewModel {
    enum State: Equatable {
        case loading
        case playing
        case failed(String)
    }

    /// AVPlayer for HLS/MP4 (native tvOS controls); VLC for containers
    /// AVPlayer can't open, such as the MKV most Xtream VOD uses.
    enum Backend: Equatable {
        case avPlayer
        case vlc
    }

    private(set) var item: PlayableItem
    private(set) var state: State = .loading
    private(set) var backend: Backend = .avPlayer
    /// Set when a VLC stream reaches the end, so the view can close.
    private(set) var didFinish = false
    /// Shown briefly after a channel change.
    private(set) var channelBanner: Channel?
    /// Kept across videos (saved in Preferences).
    private(set) var aspectMode: VideoAspectMode
    /// VLC only; AVPlayer's speed lives in its own transport bar control.
    private(set) var speed: Float = PlaybackSpeed.normal

    let player = AVPlayer()
    #if canImport(LabbyVLC)
    /// Created on first use: VLC's engine is heavy and live TV never needs it.
    private(set) var vlc: VLCPlaybackEngine?
    @ObservationIgnored private var vlcTask: Task<Void, Never>?
    #endif

    @ObservationIgnored private let catalog: any CatalogRepository
    @ObservationIgnored private let history: any WatchHistoryRepository
    @ObservationIgnored private let preferences: Preferences
    @ObservationIgnored private var statusObservation: NSKeyValueObservation?
    @ObservationIgnored private var timeObserver: Any?
    @ObservationIgnored private var endTask: Task<Void, Never>?
    @ObservationIgnored private var bannerTask: Task<Void, Never>?
    @ObservationIgnored private var pendingSeek: Double?
    @ObservationIgnored private var streamExtension = ""
    @ObservationIgnored private var streamIsInsecure = false
    @ObservationIgnored private var loadGeneration = 0

    /// How often progress is sent to `/watch-history/update` (Flutter uses 10 s).
    private static let syncInterval: Double = 10

    init(item: PlayableItem, catalog: any CatalogRepository, history: any WatchHistoryRepository, preferences: Preferences) {
        self.item = item
        self.catalog = catalog
        self.history = history
        self.preferences = preferences
        self.aspectMode = preferences.videoAspectMode
    }

    var canChangeSpeed: Bool { !item.isLive }

    func setAspectMode(_ mode: VideoAspectMode) {
        aspectMode = mode
        preferences.videoAspectMode = mode
        #if canImport(LabbyVLC)
        vlc?.setVideoScaling(crop: mode.vlcCropGeometry, aspectRatio: mode.vlcAspectRatio)
        #endif
    }

    func setSpeed(_ rate: Float) {
        guard canChangeSpeed else { return }
        speed = rate
        #if canImport(LabbyVLC)
        if backend == .vlc { vlc?.setRate(rate) }
        #endif
    }

    var canSwitchChannels: Bool {
        if case .live(_, let lineup) = item { return lineup.count > 1 }
        return false
    }

    func start() async {
        await load(item)
    }

    func retry() async {
        await load(item)
    }

    /// Swipe/click up = previous channel, down = next (offset -1 / +1).
    func switchChannel(by offset: Int) async {
        guard case .live(let current, let lineup) = item,
              let next = ChannelSwitcher.channel(from: current, in: lineup, offset: offset) else { return }
        item = .live(next, lineup: lineup)
        showBanner(for: next)
        await load(item)
    }

    /// Saves progress and releases the stream. Call when the player closes.
    func stop() async {
        await syncProgress()
        teardown()
        player.replaceCurrentItem(with: nil)
        #if canImport(LabbyVLC)
        vlc?.stop()
        #endif
    }

    // MARK: Loading

    private func load(_ item: PlayableItem) async {
        loadGeneration += 1
        let generation = loadGeneration
        teardown()
        state = .loading
        pendingSeek = nil
        didFinish = false

        do {
            let url = try await resolveURL(for: item)
            guard generation == loadGeneration else { return }
            streamExtension = url.pathExtension.lowercased()
            streamIsInsecure = url.scheme?.lowercased() == "http"

            if let videoID = historyVideoID(for: item), !item.isLive {
                pendingSeek = try? await history.status(videoID: videoID).resumePosition
                guard generation == loadGeneration else { return }
            }

            #if canImport(LabbyVLC)
            if !item.isLive && Self.needsVLC(extension: streamExtension) {
                let finalURL: URL
                do {
                    finalURL = try await StreamURLResolver.resolve(url, userAgent: Self.streamUserAgent)
                } catch let failure as StreamURLResolver.Failure {
                    guard generation == loadGeneration else { return }
                    Logger.player.error("Stream test: \(self.logType(for: item), privacy: .public) .\(self.streamExtension, privacy: .public) → provider \(String(describing: failure), privacy: .public)")
                    state = .failed(Self.message(for: failure))
                    return
                }
                guard generation == loadGeneration else { return }
                startVLC(url: finalURL, generation: generation)
                return
            }
            #endif

            backend = .avPlayer
            // defaultRate carries over between items; live must stay at 1×.
            if item.isLive { player.defaultRate = PlaybackSpeed.normal }
            // Some Xtream panels refuse unknown players (403); identify as the
            // ffmpeg-based player the Android app uses, which they accept.
            let asset = AVURLAsset(url: url, options: [AVURLAssetHTTPUserAgentKey: Self.streamUserAgent])
            let playerItem = AVPlayerItem(asset: asset)
            playerItem.externalMetadata = metadata(for: item)
            observe(playerItem)
            player.replaceCurrentItem(with: playerItem)
            player.play()

            if case .live = item {
                await recordLiveView()
            }
        } catch is CancellationError {
            return
        } catch {
            guard generation == loadGeneration else { return }
            state = .failed((error as? APIError)?.userMessage ?? APIError.unknown.userMessage)
        }
    }

    /// Containers AVPlayer can open. Anything else goes to VLC (when linked).
    nonisolated static let avPlayerExtensions: Set<String> = ["m3u8", "mp4", "m4v", "mov", "m4a", "mp3", "aac"]

    nonisolated static func needsVLC(extension ext: String) -> Bool {
        !ext.isEmpty && !avPlayerExtensions.contains(ext.lowercased())
    }

    #if canImport(LabbyVLC)
    private func startVLC(url: URL, generation: Int) {
        backend = .vlc
        #if DEBUG
        if vlc == nil { VLCPlaybackEngine.enableDebugLogging() }
        #endif
        let engine = vlc ?? VLCPlaybackEngine()
        vlc = engine
        engine.load(url: url, startAt: pendingSeek, userAgent: Self.streamUserAgent)
        engine.setVideoScaling(crop: aspectMode.vlcCropGeometry, aspectRatio: aspectMode.vlcAspectRatio)
        engine.setRate(speed)
        pendingSeek = nil

        let type = logType(for: item)
        let ext = streamExtension
        // Polls instead of observing: two cheap reads twice a second, and it
        // also drives the 10-second progress sync, which needs a clock anyway.
        vlcTask = Task { [weak self] in
            var lastSync = Date.now
            var reportedPlaying = false
            let startedAt = Date.now
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(500))
                guard let self, generation == self.loadGeneration, let engine = self.vlc else { return }
                switch engine.status {
                case .playing, .paused:
                    if !reportedPlaying {
                        reportedPlaying = true
                        Logger.player.notice("Stream test: \(type, privacy: .public) .\(ext, privacy: .public) via VLC → plays")
                    }
                    self.state = .playing
                    if Date.now.timeIntervalSince(lastSync) >= Self.syncInterval {
                        lastSync = .now
                        await self.syncProgress()
                    }
                case .failed:
                    Logger.player.error("Stream test: \(type, privacy: .public) .\(ext, privacy: .public) via VLC → failed")
                    self.state = .failed(Self.vlcFailureMessage)
                    return
                case .ended:
                    await self.syncProgress()
                    self.didFinish = true
                    return
                case .idle, .opening, .buffering:
                    // Don't spin forever on a dead or very slow server.
                    if !reportedPlaying && Date.now.timeIntervalSince(startedAt) > Self.vlcStartTimeout {
                        Logger.player.error("Stream test: \(type, privacy: .public) .\(ext, privacy: .public) via VLC → timed out (status \(String(describing: engine.status), privacy: .public))")
                        engine.stop()
                        self.state = .failed("The video took too long to start. The server may be busy or offline.")
                        return
                    }
                }
            }
        }
    }
    #endif

    /// What media_kit/mpv sends on Android (see Flutter `StreamFailureDiagnosis`).
    nonisolated static let streamUserAgent = "Lavf/60.3.100"

    /// Redirects are resolved before VLC starts, so this only covers buffering.
    nonisolated static let vlcStartTimeout: TimeInterval = 60

    nonisolated static func message(for failure: StreamURLResolver.Failure) -> String {
        switch failure {
        case .refused(let status):
            "Your IPTV provider refused this video (HTTP \(status)). It may not be available on your plan right now."
        case .notFound:
            "Your IPTV provider no longer has this video."
        case .unreachable:
            "Couldn't reach your IPTV provider's server. Please try again."
        }
    }

    nonisolated static let vlcFailureMessage = "This video couldn't be played. The stream may be offline or damaged."

    private func resolveURL(for item: PlayableItem) async throws -> URL {
        switch item {
        case .live(let channel, _):
            return try await catalog.liveStreamURL(channelID: channel.id)
        case .movie(let id, _, _):
            let detail = try await catalog.movieDetail(id: id)
            guard let url = detail.playURL else {
                throw APIError.server(status: 0, message: "This movie has no playable stream.")
            }
            return url
        case .episode(let episode, let context):
            preferences.remember(context, for: episode)
            return try await catalog.episodeURL(for: episode)
        }
    }

    private func observe(_ playerItem: AVPlayerItem) {
        // KVO fires on an arbitrary thread: copy the values, then hop to the main actor.
        statusObservation = playerItem.observe(\.status, options: [.new]) { @Sendable [weak self] item, _ in
            guard let self else { return }
            let status = item.status
            let errorDescription = item.error?.localizedDescription
            // Often empty: AVFoundation hides the network cause behind a
            // generic error, so an ATS block is also detected from Info.plist.
            let urlErrorCodes = Self.urlErrorCodes(in: item.error)
            Task { @MainActor in
                self.handle(status: status, errorDescription: errorDescription, urlErrorCodes: urlErrorCodes)
            }
        }

        timeObserver = player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: Self.syncInterval, preferredTimescale: 1),
            queue: .main
        ) { @Sendable [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                await self.syncProgress()
            }
        }

        let finished = NotificationCenter.default.notifications(named: AVPlayerItem.didPlayToEndTimeNotification, object: playerItem)
        endTask = Task { @MainActor [weak self] in
            for await _ in finished {
                await self?.syncProgress()
            }
        }
    }

    private func handle(status: AVPlayerItem.Status, errorDescription: String?, urlErrorCodes: [Int]) {
        let type = logType(for: item)
        switch status {
        case .readyToPlay:
            Logger.player.notice("Stream test: \(type, privacy: .public) .\(self.streamExtension, privacy: .public) → plays")
            if let seek = pendingSeek {
                pendingSeek = nil
                player.seek(to: CMTime(seconds: seek, preferredTimescale: 600))
            }
            state = .playing
        case .failed:
            Logger.player.error("Stream test: \(type, privacy: .public) .\(self.streamExtension, privacy: .public) → failed (URL errors \(urlErrorCodes, privacy: .public)): \(errorDescription ?? "unknown", privacy: .public)")
            var codes = urlErrorCodes
            if streamIsInsecure && !Self.allowsInsecureMedia {
                codes.insert(NSURLErrorAppTransportSecurityRequiresSecureConnection, at: 0)
            }
            state = .failed(Self.failureMessage(extension: streamExtension, urlErrorCodes: codes))
        default:
            break
        }
    }

    /// AVPlayer plays HLS and MP4/MOV/M4V. Xtream VOD is often MKV/AVI,
    /// which it can't decode, so say that plainly instead of a generic error.
    static func failureMessage(extension ext: String, urlErrorCodes: [Int] = []) -> String {
        // A network failure has to be reported before the format guess,
        // otherwise a blocked or offline .mkv looks like a codec problem.
        if urlErrorCodes.contains(NSURLErrorAppTransportSecurityRequiresSecureConnection) {
            return "This stream uses an insecure (http) connection, which this build of the app blocks. (Developer: allow arbitrary loads in App Transport Security.)"
        }
        if let code = urlErrorCodes.first {
            switch code {
            case NSURLErrorNotConnectedToInternet, NSURLErrorNetworkConnectionLost:
                return "No internet connection. Check your network and try again."
            case NSURLErrorTimedOut, NSURLErrorCannotFindHost, NSURLErrorCannotConnectToHost:
                return "The stream server isn't responding. It may be offline."
            default:
                break
            }
        }
        return switch ext {
        case "mkv", "avi", "wmv", "flv":
            "This video is in .\(ext) format, which Apple TV can't play."
        case "ts":
            "This stream is raw MPEG-TS, which Apple TV can't play directly."
        default:
            "This stream couldn't be played. It may be offline or in an unsupported format."
        }
    }

    /// True when Info.plist lets AVPlayer load `http://` streams
    /// (`NSAllowsArbitraryLoads` or `NSAllowsArbitraryLoadsForMedia`).
    /// Xtream providers almost always serve plain http.
    nonisolated static var allowsInsecureMedia: Bool {
        allowsInsecureMedia(infoDictionary: Bundle.main.infoDictionary ?? [:])
    }

    nonisolated static func allowsInsecureMedia(infoDictionary: [String: Any]) -> Bool {
        guard let ats = infoDictionary["NSAppTransportSecurity"] as? [String: Any] else { return false }
        return (ats["NSAllowsArbitraryLoads"] as? Bool) == true
            || (ats["NSAllowsArbitraryLoadsForMedia"] as? Bool) == true
    }

    /// AVFoundation wraps the real cause in `NSUnderlyingError`; collect
    /// every NSURLErrorDomain code in the chain.
    nonisolated static func urlErrorCodes(in error: (any Error)?) -> [Int] {
        var codes: [Int] = []
        var current = error.map { $0 as NSError }
        while let nsError = current {
            if nsError.domain == NSURLErrorDomain { codes.append(nsError.code) }
            current = nsError.userInfo[NSUnderlyingErrorKey] as? NSError
        }
        return codes
    }

    // MARK: Watch history

    private func historyVideoID(for item: PlayableItem) -> String? {
        switch item {
        case .live(let channel, _): String(channel.id)
        case .movie(let id, _, _): String(id)
        case .episode(let episode, _): episode.id
        }
    }

    private func syncProgress() async {
        guard !item.isLive, state == .playing,
              let videoID = historyVideoID(for: item),
              let (position, duration) = playbackTimes() else { return }
        guard duration.isFinite, duration > 0, position.isFinite else { return }

        var request: UpdateVideoStatusRequest
        switch item {
        case .movie(_, let title, let thumbnail):
            request = UpdateVideoStatusRequest(title: title, videoId: videoID, videoType: "movie")
            request.thumbnail = thumbnail.isEmpty ? nil : thumbnail
        case .episode(let episode, let context):
            request = UpdateVideoStatusRequest(title: item.title, videoId: videoID, videoType: "series")
            request.seasonNumber = episode.season
            request.episodeNumber = episode.episodeNum
            request.thumbnail = context.cover.isEmpty ? nil : context.cover
        case .live:
            return
        }
        request.currentTime = position.rounded()
        request.duration = duration.rounded()
        try? await history.update(request)
    }

    /// Live channels appear in history so "recently watched" works, like Flutter.
    private func recordLiveView() async {
        guard case .live(let channel, _) = item else { return }
        var request = UpdateVideoStatusRequest(title: channel.name.isEmpty ? "Live TV" : channel.name, videoId: String(channel.id), videoType: "live")
        request.thumbnail = channel.streamIcon.isEmpty ? nil : channel.streamIcon
        try? await history.update(request)
    }

    /// Position and duration in seconds from whichever engine is playing.
    private func playbackTimes() -> (Double, Double)? {
        switch backend {
        case .avPlayer:
            guard let current = player.currentItem else { return nil }
            return (player.currentTime().seconds, current.duration.seconds)
        case .vlc:
            #if canImport(LabbyVLC)
            guard let vlc else { return nil }
            return (vlc.currentTime, vlc.duration)
            #else
            return nil
            #endif
        }
    }

    // MARK: Helpers

    private func metadata(for item: PlayableItem) -> [AVMetadataItem] {
        let title = AVMutableMetadataItem()
        title.identifier = .commonIdentifierTitle
        title.value = item.title as NSString
        title.extendedLanguageTag = "und"
        return [title]
    }

    private func showBanner(for channel: Channel) {
        channelBanner = channel
        bannerTask?.cancel()
        bannerTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(3))
            guard !Task.isCancelled else { return }
            self?.channelBanner = nil
        }
    }

    private func logType(for item: PlayableItem) -> String {
        switch item {
        case .live: "live"
        case .movie: "movie"
        case .episode: "series"
        }
    }

    private func teardown() {
        statusObservation?.invalidate()
        statusObservation = nil
        if let timeObserver {
            player.removeTimeObserver(timeObserver)
        }
        timeObserver = nil
        endTask?.cancel()
        endTask = nil
        #if canImport(LabbyVLC)
        vlcTask?.cancel()
        vlcTask = nil
        #endif
    }
}
