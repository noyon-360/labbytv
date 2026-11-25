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

    // MARK: Remote navigation along the timeline

    /// The guide doesn't go back past the current half hour (no catch-up).
    private var earliestStart: Date { max(fetchStart, DateFormatting.floorToHalfHour(now)) }
    private var latestStart: Date { fetchEnd.addingTimeInterval(-Self.windowLength) }
    var canSlideEarlier: Bool { windowStart > earliestStart }

    /// Moving right past the row's last visible programme: the programme to
    /// focus next, after sliding the window so it shows. Nil at the end of
    /// the provider's data.
    func slideForward(channelID: Int) -> EPGProgram? {
        let list = programs[channelID] ?? []
        guard let last = visiblePrograms(for: channelID).last,
              let target = GuideTimeline.program(after: last, in: list) ?? (last.end > windowEnd ? last : nil) else { return nil }
        reveal(target)
        return target
    }

    /// Moving left off the row's first visible programme while the window is
    /// in the future: the programme to focus instead of the channel cell.
    func slideBack(from programID: String, channelID: Int) -> EPGProgram? {
        guard canSlideEarlier,
              let current = program(channelID: channelID, programID: programID) else { return nil }
        let list = programs[channelID] ?? []
        let target = current.start < windowStart ? current : GuideTimeline.program(before: current, in: list)
        guard let target, target.end > earliestStart else { return nil }
        reveal(target)
        return target
    }

    private func reveal(_ program: EPGProgram) {
        windowStart = GuideTimeline.windowStart(showing: program, current: windowStart, length: Self.windowLength, earliest: earliestStart, latest: latestStart)
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
