import Foundation
import Testing
@testable import labbytv

struct EPGProgramTests {
    @Test func decodesBase64TitleAndUnixTimes() throws {
        let title = Data("Evening News".utf8).base64EncodedString()
        let json = #"{"id":"1","title":"\#(title)","description":"","start_timestamp":"1700000000","stop_timestamp":1700001800}"#
        let program = try JSONDecoder().decode(EPGProgram.self, from: Data(json.utf8))
        #expect(program.title == "Evening News")
        #expect(program.start == Date(timeIntervalSince1970: 1_700_000_000))
        #expect(program.end.timeIntervalSince(program.start) == 1800)
    }

    @Test func plainTextTitleFallsBack() {
        #expect(Base64.decodedText("Not base64!") == "Not base64!")
        #expect(Base64.decodedText("") == "")
    }

    @Test func airingAndProgress() {
        let start = Date(timeIntervalSince1970: 0)
        let program = EPGProgram(id: "x", title: "T", description: "", start: start, end: start.addingTimeInterval(100))
        #expect(program.isAiring(at: start.addingTimeInterval(50)))
        #expect(!program.isAiring(at: start.addingTimeInterval(100)))
        #expect(program.progress(at: start.addingTimeInterval(25)) == 0.25)
    }

    @Test func windowFilterKeepsOverlappingPrograms() {
        let base = Date(timeIntervalSince1970: 0)
        func program(_ s: Double, _ e: Double) -> EPGProgram {
            EPGProgram(id: "\(s)", title: "", description: "", start: base.addingTimeInterval(s), end: base.addingTimeInterval(e))
        }
        let list = [program(200, 300), program(-50, 10), program(400, 500)]
        let visible = GuideViewModel.programs(list, overlapping: base, base.addingTimeInterval(350))
        #expect(visible.map(\.id) == ["-50.0", "200.0"])
    }

    @Test func floorsToHalfHour() {
        let date = Date(timeIntervalSince1970: 1800 * 10 + 1234)
        #expect(DateFormatting.floorToHalfHour(date) == Date(timeIntervalSince1970: 18000))
    }
}
