import Foundation
import Testing
@testable import labbytv

struct NowNextTests {
    private let base = Date(timeIntervalSince1970: 1_800_000_000)

    private func program(_ id: String, _ startMinutes: Double, _ endMinutes: Double) -> EPGProgram {
        EPGProgram(id: id, title: id, description: "", start: base.addingTimeInterval(startMinutes * 60), end: base.addingTimeInterval(endMinutes * 60))
    }

    @Test func findsNowAndNextInUnsortedList() {
        let list = [program("c", 60, 90), program("a", 0, 30), program("b", 30, 60)]
        let result = NowNext(programs: list, at: base.addingTimeInterval(40 * 60))
        #expect(result.now?.id == "b")
        #expect(result.next?.id == "c")
    }

    @Test func gapHasNoNowButAnUpcomingNext() {
        let list = [program("a", 0, 30), program("b", 60, 90)]
        let result = NowNext(programs: list, at: base.addingTimeInterval(45 * 60))
        #expect(result.now == nil)
        #expect(result.next?.id == "b")
    }

    @Test func emptyScheduleIsEmpty() {
        #expect(NowNext(programs: [], at: base).isEmpty)
    }
}
