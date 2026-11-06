import Foundation
import Observation
import TVVLCKit
import UIKit

/// Main-actor wrapper around `VLCMediaPlayer` with observable state for SwiftUI.
@MainActor
@Observable
public final class VLCPlaybackEngine {
    public enum Status: Equatable, Sendable {
        case idle, opening, buffering, playing, paused, ended, failed
    }

    public private(set) var status: Status = .idle
    /// Seconds.
    public private(set) var currentTime: Double = 0
    /// Seconds; 0 until VLC knows the length.
    public private(set) var duration: Double = 0
    public private(set) var audioTracks: [VLCTrack] = []
    public private(set) var subtitleTracks: [VLCTrack] = []
    public private(set) var selectedAudioTrack: Int32 = -1
    public private(set) var selectedSubtitleTrack: Int32 = -1

    @ObservationIgnored let mediaPlayer = VLCMediaPlayer()
    /// VLC draws here. It's handed to VLC before `play()`: with no drawable
    /// at start, VLC on tvOS can sit in "opening" forever.
    @ObservationIgnored let videoView: UIView = {
        let view = UIView()
        view.backgroundColor = .black
        view.isUserInteractionEnabled = false
        return view
    }()
    @ObservationIgnored private var bridge: DelegateBridge?

    public init() {
        let bridge = DelegateBridge(owner: self)
        self.bridge = bridge
        mediaPlayer.delegate = bridge
        mediaPlayer.drawable = videoView
    }

    /// Prints libVLC's own log to the console (use in debug builds only).
    public static func enableDebugLogging() {
        let logger = VLCConsoleLogger()
        logger.level = .info
        VLCLibrary.shared().loggers = [logger]
    }

    /// `startAt` resumes from a saved position (seconds).
    /// `userAgent` replaces VLC's own, which some IPTV panels refuse.
    public func load(url: URL, startAt: Double? = nil, userAgent: String? = nil) {
        let media = VLCMedia(url: url)
        if let userAgent {
            media.addOption(":http-user-agent=\(userAgent)")
        }
        // IPTV servers can be slow to start; a larger buffer avoids stalls.
        media.addOption(":network-caching=1500")
        if let startAt, startAt > 0 {
            media.addOption(":start-time=\(Int(startAt))")
        }
        status = .opening
        currentTime = startAt ?? 0
        duration = 0
        audioTracks = []
        subtitleTracks = []
        mediaPlayer.media = media
        mediaPlayer.play()
    }

    public func play() { mediaPlayer.play() }
    public func pause() { mediaPlayer.pause() }

    public func togglePlayPause() {
        mediaPlayer.isPlaying ? mediaPlayer.pause() : mediaPlayer.play()
    }

    public func seek(to seconds: Double) {
        guard mediaPlayer.isSeekable else { return }
        let clamped = max(0, duration > 0 ? min(seconds, duration - 1) : seconds)
        mediaPlayer.time = VLCTime(int: Int32(clamped * 1000))
        currentTime = clamped
    }

    public func jump(by seconds: Double) {
        seek(to: currentTime + seconds)
    }

    public func selectAudioTrack(_ id: Int32) {
        mediaPlayer.currentAudioTrackIndex = id
        selectedAudioTrack = id
    }

    /// Pass `-1` to turn subtitles off.
    public func selectSubtitleTrack(_ id: Int32) {
        mediaPlayer.currentVideoSubTitleIndex = id
        selectedSubtitleTrack = id
    }

    public func stop() {
        mediaPlayer.stop()
        status = .idle
    }


    // MARK: Delegate callbacks

    fileprivate func stateChanged() {
        switch mediaPlayer.state {
        case .opening: status = .opening
        case .buffering:
            // VLC reports buffering while already playing; keep "playing" then.
            if !mediaPlayer.isPlaying { status = .buffering }
        case .playing: status = .playing
        case .paused: status = .paused
        case .ended: status = .ended
        case .error: status = .failed
        case .stopped:
            if status != .ended && status != .failed { status = .idle }
        case .esAdded: refreshTracks()
        @unknown default: break
        }
        refreshTracks()
    }

    fileprivate func timeChanged() {
        if let ms = mediaPlayer.time.value?.doubleValue {
            currentTime = ms / 1000
        }
        if duration == 0, let ms = mediaPlayer.media?.length.value?.doubleValue, ms > 0 {
            duration = ms / 1000
        }
        if status == .buffering || status == .opening, mediaPlayer.isPlaying {
            status = .playing
        }
    }

    private func refreshTracks() {
        audioTracks = Self.tracks(names: mediaPlayer.audioTrackNames, indexes: mediaPlayer.audioTrackIndexes)
        subtitleTracks = Self.tracks(names: mediaPlayer.videoSubTitlesNames, indexes: mediaPlayer.videoSubTitlesIndexes)
        selectedAudioTrack = mediaPlayer.currentAudioTrackIndex
        selectedSubtitleTrack = mediaPlayer.currentVideoSubTitleIndex
    }

    private static func tracks(names: [Any], indexes: [Any]) -> [VLCTrack] {
        zip(names, indexes).compactMap { name, index in
            guard let id = (index as? NSNumber)?.int32Value else { return nil }
            return VLCTrack(id: id, name: (name as? String) ?? "Track \(id)")
        }
    }
}

/// VLCKit calls its delegate from its own threads, so hop to the main actor
/// before touching the engine.
private final class DelegateBridge: NSObject, VLCMediaPlayerDelegate, @unchecked Sendable {
    // Weak: the engine owns the bridge (via the player's delegate).
    nonisolated(unsafe) weak var owner: VLCPlaybackEngine?

    init(owner: VLCPlaybackEngine) {
        self.owner = owner
    }

    func mediaPlayerStateChanged(_ aNotification: Notification) {
        Task { @MainActor [weak self] in self?.owner?.stateChanged() }
    }

    func mediaPlayerTimeChanged(_ aNotification: Notification) {
        Task { @MainActor [weak self] in self?.owner?.timeChanged() }
    }
}
