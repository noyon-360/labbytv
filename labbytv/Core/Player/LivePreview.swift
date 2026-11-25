import AVFoundation
import Foundation
import Observation
import os

/// One live stream shared by the guide's mini player and the full-screen
/// player. Going full screen and pressing Back again keeps the same
/// AVPlayer, so the channel never restarts (client: opening the guide must
/// not interrupt the current stream).
@MainActor
@Observable
final class LivePreview {
    enum State: Equatable {
        case idle
        case loading
        case playing
        case failed(String)
    }

    let player = AVPlayer()
    private(set) var channel: Channel?
    private(set) var lineup: [Channel] = []
    private(set) var state: State = .idle

    @ObservationIgnored private let catalog: any CatalogRepository
    @ObservationIgnored private var statusObservation: NSKeyValueObservation?
    @ObservationIgnored private var generation = 0

    init(catalog: any CatalogRepository) {
        self.catalog = catalog
    }

    /// True when `channel` is already loaded, so the full-screen player can
    /// take over the running stream instead of loading it again.
    func isShowing(_ channel: Channel) -> Bool {
        self.channel?.id == channel.id && player.currentItem != nil && state != .idle
    }

    func play(_ channel: Channel, lineup: [Channel]) async {
        generation += 1
        let current = generation
        self.channel = channel
        self.lineup = lineup
        state = .loading
        statusObservation = nil
        do {
            let url = try await catalog.liveStreamURL(channelID: channel.id)
            guard current == generation else { return }
            let asset = AVURLAsset(url: url, options: [AVURLAssetHTTPUserAgentKey: PlayerViewModel.streamUserAgent])
            let item = AVPlayerItem(asset: asset)
            observe(item, generation: current)
            player.defaultRate = PlaybackSpeed.normal
            player.replaceCurrentItem(with: item)
            player.play()
        } catch is CancellationError {
            return
        } catch {
            guard current == generation else { return }
            state = .failed((error as? APIError)?.userMessage ?? APIError.unknown.userMessage)
        }
    }

    /// The full-screen player switched channel on this player.
    func adopt(_ channel: Channel, lineup: [Channel]) {
        generation += 1
        self.channel = channel
        self.lineup = lineup
        statusObservation = nil
        state = .playing
    }

    func stop() {
        generation += 1
        statusObservation = nil
        player.replaceCurrentItem(with: nil)
        channel = nil
        lineup = []
        state = .idle
    }

    private func observe(_ item: AVPlayerItem, generation: Int) {
        statusObservation = item.observe(\.status, options: [.new]) { @Sendable [weak self] item, _ in
            let status = item.status
            Task { @MainActor in
                guard let self, generation == self.generation else { return }
                switch status {
                case .readyToPlay: self.state = .playing
                case .failed: self.state = .failed("This channel couldn't be played. It may be offline.")
                default: break
                }
            }
        }
    }
}
