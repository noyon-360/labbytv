import Foundation
import Testing
@testable import labbytv

struct GuideTimelineTests {
    /// A half-hour boundary.
    private let base = Date(timeIntervalSince1970: 1_800_000_000 - 1_800_000_000.truncatingRemainder(dividingBy: 1800))
    private let length: TimeInterval = 3 * 3600

    private func program(_ id: String, _ startMinutes: Double, _ endMinutes: Double) -> EPGProgram {
        EPGProgram(id: id, title: id, description: "", start: base.addingTimeInterval(startMinutes * 60), end: base.addingTimeInterval(endMinutes * 60))
    }

    private func minutes(_ date: Date) -> Double { date.timeIntervalSince(base) / 60 }

    @Test func nextAndPreviousProgramme() {
        let list = [program("a", 0, 60), program("b", 60, 120), program("c", 150, 210)]
        #expect(GuideTimeline.program(after: list[1], in: list)?.id == "c")
        #expect(GuideTimeline.program(before: list[1], in: list)?.id == "a")
        #expect(GuideTimeline.program(after: list[2], in: list) == nil)
        #expect(GuideTimeline.program(before: list[0], in: list) == nil)
    }

    @Test func visibleProgrammeDoesNotMoveTheWindow() {
        let start = GuideTimeline.windowStart(showing: program("a", 60, 90), current: base, length: length, earliest: base, latest: base.addingTimeInterval(86_400))
        #expect(start == base)
    }

    @Test func programmeBeyondTheRightEdgeSlidesForwardWithAnHourOfContext() {
        let start = GuideTimeline.windowStart(showing: program("late", 200, 260), current: base, length: length, earliest: base, latest: base.addingTimeInterval(86_400))
        #expect(minutes(start) == 120)
    }

    @Test func programmeBeforeTheLeftEdgeSlidesBack() {
        let current = base.addingTimeInterval(4 * 3600)
        let start = GuideTimeline.windowStart(showing: program("early", 200, 260), current: current, length: length, earliest: base, latest: base.addingTimeInterval(86_400))
        #expect(minutes(start) == 180)
    }

    @Test func neverBeforeEarliestOrAfterLatest() {
        let early = GuideTimeline.windowStart(showing: program("past", -120, -60), current: base, length: length, earliest: base, latest: base.addingTimeInterval(86_400))
        #expect(early == base)
        let latest = base.addingTimeInterval(3600)
        let late = GuideTimeline.windowStart(showing: program("far", 600, 660), current: base, length: length, earliest: base, latest: latest)
        #expect(late == latest)
    }
}
