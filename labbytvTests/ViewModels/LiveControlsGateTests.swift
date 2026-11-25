import Foundation
import Testing
@testable import labbytv

struct LiveControlsGateTests {
    private let start = Date(timeIntervalSince1970: 1_000)

    @Test func hiddenControlsAllowChannelStep() {
        #expect(LiveControlsGate().allowsChannelStep(at: start))
    }

    @Test func controlsOpenedWithSelectKeepUpDownForTheButtons() {
        var gate = LiveControlsGate()
        gate.userPressedSelect()
        gate.controlsWillChange(visible: true, at: start)
        #expect(!gate.allowsChannelStep(at: start.addingTimeInterval(1)))
    }

    @Test func barShownBySurfingDoesNotBlockTheNextChannel() {
        var gate = LiveControlsGate()
        gate.channelStepped(at: start)
        gate.controlsWillChange(visible: true, at: start.addingTimeInterval(0.02))
        #expect(gate.allowsChannelStep(at: start.addingTimeInterval(1.5)))
    }

    @Test func barShownJustBeforeTheStepCountsAsSurfing() {
        var gate = LiveControlsGate()
        gate.controlsWillChange(visible: true, at: start)
        gate.channelStepped(at: start.addingTimeInterval(0.1))
        #expect(gate.allowsChannelStep(at: start.addingTimeInterval(2)))
    }

    @Test func selectDuringSurfingHandsUpDownToTheButtons() {
        var gate = LiveControlsGate()
        gate.channelStepped(at: start)
        gate.controlsWillChange(visible: true, at: start)
        gate.userPressedSelect()
        #expect(!gate.allowsChannelStep(at: start.addingTimeInterval(1)))
    }

    @Test func hidingResetsEverything() {
        var gate = LiveControlsGate()
        gate.controlsWillChange(visible: true, at: start)
        gate.controlsWillChange(visible: false, at: start.addingTimeInterval(5))
        #expect(gate.allowsChannelStep(at: start.addingTimeInterval(6)))
        #expect(!gate.openedBySurfing)
    }
}
