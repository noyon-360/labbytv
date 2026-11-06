import Foundation
import Testing
@testable import labbytv

struct PagingAndPlaybackTests {
    @Test func mergeDropsDuplicatesFromUnstableXtreamPages() {
        let first = [Channel(id: 1, name: "A"), Channel(id: 2, name: "B")]
        let second = [Channel(id: 2, name: "B"), Channel(id: 3, name: "C"), Channel(id: 3, name: "C")]
        let merged = CatalogViewModel<Channel>.merge(existing: first, incoming: second)
        #expect(merged.map(\.id) == [1, 2, 3])
    }

    @Test func channelSwitcherWraps() {
        let lineup = (1...3).map { Channel(id: $0, name: "\($0)") }
        #expect(ChannelSwitcher.channel(from: lineup[2], in: lineup, offset: 1)?.id == 1)
        #expect(ChannelSwitcher.channel(from: lineup[0], in: lineup, offset: -1)?.id == 3)
        #expect(ChannelSwitcher.channel(from: lineup[0], in: [lineup[0]], offset: 1) == nil)
    }

    @Test func resumeRulesMatchFlutter() {
        #expect(VideoStatus(currentTime: 600, duration: 6000).resumePosition == 600)
        #expect(VideoStatus(currentTime: 5995, duration: 6000).resumePosition == nil)   // < 10 s left
        #expect(VideoStatus(currentTime: 5800, duration: 6000).resumePosition == nil)   // > 95 %
        #expect(VideoStatus(currentTime: 600, duration: 6000, isCompleted: true).resumePosition == nil)
        #expect(VideoStatus().resumePosition == nil)
    }

    @Test func failureMessageNamesUnsupportedContainers() {
        #expect(PlayerViewModel.failureMessage(extension: "mkv").contains(".mkv"))
        #expect(PlayerViewModel.failureMessage(extension: "m3u8").contains("couldn't be played"))
    }

    @Test func uniqueByNameIsCaseInsensitive() {
        let movies = [Movie(id: 1, name: "Up"), Movie(id: 2, name: " up "), Movie(id: 3, name: "")]
        #expect(HomeViewModel.uniqueByName(movies).map(\.id) == [1, 3])
    }
}

struct PlayerErrorTests {
    @Test func atsBlockIsReportedBeforeFormat() {
        let underlying = NSError(domain: NSURLErrorDomain, code: NSURLErrorAppTransportSecurityRequiresSecureConnection)
        let error = NSError(domain: "AVFoundationErrorDomain", code: -11800, userInfo: [NSUnderlyingErrorKey: underlying])
        let codes = PlayerViewModel.urlErrorCodes(in: error)
        #expect(codes == [NSURLErrorAppTransportSecurityRequiresSecureConnection])
        #expect(PlayerViewModel.failureMessage(extension: "mkv", urlErrorCodes: codes).contains("http"))
    }
}

struct ATSConfigTests {
    @Test func readsInfoPlistATSKeys() {
        #expect(!PlayerViewModel.allowsInsecureMedia(infoDictionary: [:]))
        #expect(PlayerViewModel.allowsInsecureMedia(infoDictionary: ["NSAppTransportSecurity": ["NSAllowsArbitraryLoads": true]]))
        #expect(PlayerViewModel.allowsInsecureMedia(infoDictionary: ["NSAppTransportSecurity": ["NSAllowsArbitraryLoadsForMedia": true]]))
        #expect(!PlayerViewModel.allowsInsecureMedia(infoDictionary: ["NSAppTransportSecurity": ["NSAllowsArbitraryLoads": false]]))
    }
}
