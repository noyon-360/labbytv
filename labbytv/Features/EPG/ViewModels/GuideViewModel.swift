import Foundation
import Observation

/// Channels down, time across. The grid shows a 3-hour window; each
/// channel's schedule is fetched once for a wider range and cached, so
/// moving the window or scrolling back doesn't refetch.
@MainActor
@Observable
final class GuideViewModel {
    static let windowLength: TimeInterval = 3 * 3600
    static let shiftStep: TimeInterval = 90 * 60

    let channels: CatalogViewModel<Channel>
    private(set) var windowStart: Date
    private(set) var now: Date = .now
    private(set) var programs: [Int: [EPGProgram]] = [:]
    private(set) var failedChannels: Set<Int> = []

    @ObservationIgnored private let cache: EPGCache
    @ObservationIgnored private let fetchStart: Date
    @ObservationIgnored private let fetchEnd: Date

    init(channels: CatalogViewModel<Channel>, cache: EPGCache, now: Date = .now) {
        self.channels = channels
        self.cache = cache
        let start = DateFormatting.floorToHalfHour(now)
        windowStart = start
        // Wide enough for "earlier"/"later" without refetching.
        fetchStart = start.addingTimeInterval(-6 * 3600)
        fetchEnd = start.addingTimeInterval(24 * 3600)
    }

    var windowEnd: Date { windowStart.addingTimeInterval(Self.windowLength) }
    var canGoEarlier: Bool { windowStart.addingTimeInterval(-Self.shiftStep) >= fetchStart }
    var canGoLater: Bool { windowEnd.addingTimeInterval(Self.shiftStep) <= fetchEnd }

    func shiftWindow(forward: Bool) {
        let candidate = windowStart.addingTimeInterval(forward ? Self.shiftStep : -Self.shiftStep)
        if forward ? canGoLater : canGoEarlier {
            windowStart = candidate
        }
    }

    func jumpToNow() {
        windowStart = DateFormatting.floorToHalfHour(.now)
    }

    /// Called by each row's `.task(id:)`, so only visible rows load.
    func loadPrograms(for channel: Channel) async {
        guard programs[channel.id] == nil else { return }
        do {
            let list = try await cache.programs(channelID: channel.id, from: fetchStart, to: fetchEnd)
            programs[channel.id] = list
            failedChannels.remove(channel.id)
        } catch is CancellationError {
            return
        } catch {
            failedChannels.insert(channel.id)
        }
    }

    func retryPrograms(for channel: Channel) async {
        programs[channel.id] = nil
        await loadPrograms(for: channel)
    }

    func program(channelID: Int, programID: String) -> EPGProgram? {
        programs[channelID]?.first { $0.id == programID }
    }

    /// Programmes overlapping the visible window, in order.
    func visiblePrograms(for channelID: Int) -> [EPGProgram] {
        Self.programs(programs[channelID] ?? [], overlapping: windowStart, windowEnd)
    }

    /// Keeps the now-line moving.
    func tickClock() async {
        while !Task.isCancelled {
            now = .now
            try? await Task.sleep(for: .seconds(30))
        }
    }

    nonisolated static func programs(_ list: [EPGProgram], overlapping start: Date, _ end: Date) -> [EPGProgram] {
        list.filter { $0.end > start && $0.start < end }.sorted { $0.start < $1.start }
    }
}
