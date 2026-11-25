import Foundation

/// Timeline maths for moving through the guide with the remote.
nonisolated enum GuideTimeline {
    static func program(after program: EPGProgram, in list: [EPGProgram]) -> EPGProgram? {
        list.sorted { $0.start < $1.start }.first { $0.start >= program.end && $0.id != program.id }
    }

    static func program(before program: EPGProgram, in list: [EPGProgram]) -> EPGProgram? {
        list.sorted { $0.start < $1.start }.last { $0.end <= program.start && $0.id != program.id }
    }

    /// Smallest move that brings `program` into view: half-hour aligned,
    /// with an hour of context before it when moving forward.
    static func windowStart(showing program: EPGProgram, current: Date, length: TimeInterval, earliest: Date, latest: Date) -> Date {
        let end = current.addingTimeInterval(length)
        var start = current
        if program.start < current {
            start = DateFormatting.floorToHalfHour(program.start)
        } else if program.start > end.addingTimeInterval(-1800) {
            start = DateFormatting.floorToHalfHour(program.start).addingTimeInterval(-3600)
        }
        return min(max(start, earliest), max(latest, earliest))
    }
}
