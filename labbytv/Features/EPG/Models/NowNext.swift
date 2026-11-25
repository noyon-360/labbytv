import Foundation

/// The programme on now and the one after it, for the channel info overlay
/// and the player's title view.
nonisolated struct NowNext: Equatable, Sendable {
    let now: EPGProgram?
    let next: EPGProgram?

    init(now: EPGProgram?, next: EPGProgram?) {
        self.now = now
        self.next = next
    }

    /// `programs` may be unsorted and may have gaps (providers often do).
    init(programs: [EPGProgram], at date: Date) {
        let sorted = programs.sorted { $0.start < $1.start }
        let current = sorted.first { $0.isAiring(at: date) }
        now = current
        next = sorted.first { $0.start >= (current?.end ?? date) }
    }

    var isEmpty: Bool { now == nil && next == nil }
}
