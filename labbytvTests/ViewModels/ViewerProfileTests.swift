import Foundation
import Testing
@testable import labbytv

struct ProfileStartTests {
    let main = ViewerProfile(id: "m", name: "Main", isDefault: true)
    let kids = ViewerProfile(id: "k", name: "Kids", avatar: "avatar_05")

    @Test func oneProfileNeverAsks() {
        #expect(ProfileStart.decide(profiles: [main], lastProfileID: nil, askWhenSeveral: true) == .use(main))
    }

    @Test func severalAskAtAppStart() {
        #expect(ProfileStart.decide(profiles: [main, kids], lastProfileID: "k", askWhenSeveral: true) == .picker)
    }

    @Test func severalWithKnownChoiceGoStraightIn() {
        #expect(ProfileStart.decide(profiles: [main, kids], lastProfileID: "k", askWhenSeveral: false) == .use(kids))
    }

    @Test func severalWithDeletedChoiceAsk() {
        #expect(ProfileStart.decide(profiles: [main, kids], lastProfileID: "gone", askWhenSeveral: false) == .picker)
    }

    @Test func emptyListUsesBackendDefault() {
        #expect(ProfileStart.decide(profiles: [], lastProfileID: nil, askWhenSeveral: true) == .use(nil))
    }
}

struct ViewerProfileDecodingTests {
    @Test func decodesBackendList() throws {
        let json = #"""
        {"success":true,"message":"ok","data":{"profiles":[
          {"_id":"p1","name":"Noyon","avatar":"avatar_01","isDefault":true,"preferences":{"subtitleLanguage":"en","audioLanguage":"","autoplayNextEpisode":false}},
          {"_id":"p2","name":"Kids","avatar":"avatar_05","isDefault":false},
          {"name":"no id"}
        ],"maxProfiles":5,"avatars":["avatar_01"]}}
        """#
        let list = try #require(try JSONDecoder().decode(APIResponse<ViewerProfileList>.self, from: Data(json.utf8)).data)
        #expect(list.profiles.map(\.id) == ["p1", "p2"])
        #expect(list.profiles[0].isDefault)
        #expect(list.profiles[0].preferences.subtitleLanguage == "en")
        #expect(list.profiles[0].preferences.autoplayNextEpisode == false)
        #expect(list.profiles[1].preferences.autoplayNextEpisode)
        #expect(list.maxProfiles == 5)
    }

    @Test func patchBodyLeavesOutUnchangedFields() throws {
        let data = try JSONEncoder().encode(ViewerProfileRequest(name: nil, avatar: "avatar_03"))
        #expect(String(decoding: data, as: UTF8.self) == #"{"avatar":"avatar_03"}"#)
    }

    @Test func historyBodySendsCategoryOnlyWhenKnown() throws {
        var request = UpdateVideoStatusRequest(title: "News", videoId: "1", videoType: "live")
        request.setCategory(id: "", name: nil)
        #expect(!String(decoding: try JSONEncoder().encode(request), as: UTF8.self).contains("category"))
        request.setCategory(id: "7", name: "Drama")
        let json = String(decoding: try JSONEncoder().encode(request), as: UTF8.self)
        #expect(json.contains(#""categoryId":"7""#) && json.contains(#""categoryName":"Drama""#))
    }

    @Test func avatarsMatchTheBackendList() {
        #expect(AvatarPreset.all.map(\.key) == (1...12).map { String(format: "avatar_%02d", $0) })
        #expect(AvatarPreset.preset(for: "avatar_99").key == "avatar_01")
        #expect(AvatarPreset.preset(for: "avatar_01").rgb == 0xFBB41E)
    }

    @Test func onlyProfileNotFoundCountsAsGone() {
        #expect(APIClient.isProfileGone(status: 409, message: "PROFILE_NOT_FOUND: this profile no longer exists."))
        #expect(!APIClient.isProfileGone(status: 409, message: "Another profile already has this name."))
        #expect(!APIClient.isProfileGone(status: 404, message: "PROFILE_NOT_FOUND"))
    }
}

@MainActor
struct ViewerProfileStoreTests {
    private func makeStore(_ profiles: [ViewerProfile], storedID: String? = nil) -> (ViewerProfileStore, InMemorySecureStore) {
        let secure = InMemorySecureStore()
        if let storedID { secure.set(storedID, for: .viewerProfileId) }
        return (ViewerProfileStore(repository: MockViewerProfileRepository(profiles: profiles), store: secure), secure)
    }

    @Test func singleProfileOpensAppAndRemembersIt() async {
        let (store, secure) = makeStore(MockData.viewerProfiles)
        await store.start()
        #expect(store.phase == .ready)
        #expect(store.current?.id == "profile-main")
        #expect(secure.string(for: .viewerProfileId) == "profile-main")
    }

    @Test func severalProfilesAskWithLastHighlighted() async {
        let (store, _) = makeStore(MockData.severalViewerProfiles, storedID: "profile-kids")
        await store.start()
        #expect(store.phase == .picker)
        #expect(WhoIsWatchingViewModel(store: store).initialFocusID == "profile-kids")
        // First launch: no way back into the app without choosing.
        #expect(!store.canCancelPicker)
        store.select(store.profiles[1])
        #expect(store.phase == .ready && store.current?.name == "Kids")
    }

    @Test func profileDeletedElsewhereAsksAgain() async {
        let (store, _) = makeStore(MockData.severalViewerProfiles)
        await store.load()
        store.select(store.profiles[2])
        await store.profileWasDeleted()
        #expect(store.phase == .picker)
        #expect(store.current == nil)
    }

    @Test func afterSignInOnlyAsksWhenNeeded() async {
        let (store, secure) = makeStore(MockData.severalViewerProfiles)
        await store.start()          // app start: asks
        store.select(store.profiles[0])
        store.reset()                // sign-out
        secure.remove(.viewerProfileId)
        await store.start()          // next sign-in: no saved choice, so asks
        #expect(store.phase == .picker)
    }

    @Test func switchProfileCanBeCancelled() async {
        let (store, _) = makeStore(MockData.severalViewerProfiles)
        await store.load()
        store.select(store.profiles[0])
        await store.showPicker()
        #expect(store.canCancelPicker)
        store.cancelPicker()
        #expect(store.phase == .ready && store.current?.id == "profile-main")
    }

    @Test func deletingTheActiveProfileForgetsIt() async {
        let (store, secure) = makeStore(MockData.severalViewerProfiles)
        await store.load()
        store.select(store.profiles[1])
        #expect(await store.delete(store.profiles[1]) == nil)
        #expect(store.current == nil)
        #expect(secure.string(for: .viewerProfileId) == nil)
        #expect(store.profiles.count == 2)
    }

    @Test func editValidatesNameAndReportsDuplicates() async {
        let (store, _) = makeStore(MockData.severalViewerProfiles)
        await store.load()
        let add = EditViewerProfileViewModel(profile: nil, store: store)
        add.name = "   "
        #expect(await add.save() == false)
        #expect(add.error?.contains("1–20") == true)
        add.name = "kids"
        #expect(await add.save() == false)
        #expect(add.error == "Another profile already has this name.")
        add.name = " Dad "
        #expect(await add.save())
        #expect(store.profiles.last?.name == "Dad")
        // Starts on an avatar no other profile uses.
        #expect(!["avatar_01", "avatar_05", "avatar_09"].contains(add.avatar))
    }

    @Test func mainProfileCantBeDeleted() async {
        let (store, _) = makeStore(MockData.severalViewerProfiles)
        await store.load()
        let edit = EditViewerProfileViewModel(profile: store.profiles[0], store: store)
        #expect(!edit.canDelete && edit.isMainProfile)
        #expect(await edit.delete() == false)
    }
}
