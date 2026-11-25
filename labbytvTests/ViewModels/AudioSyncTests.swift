import Testing
@testable import labbytv

struct AudioSyncTests {
    @Test func stepsAndClamps() {
        #expect(AudioSync.adjusted(0, by: AudioSync.step) == 50)
        #expect(AudioSync.adjusted(-4990, by: -50) == -AudioSync.limit)
        #expect(AudioSync.adjusted(4990, by: 50) == AudioSync.limit)
    }

    @Test func labels() {
        #expect(AudioSync.label(0) == "In sync (0 ms)")
        #expect(AudioSync.label(150) == "Audio 150 ms later")
        #expect(AudioSync.label(-100) == "Audio 100 ms earlier")
    }
}
