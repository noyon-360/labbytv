import Foundation
import Testing
@testable import labbytv

struct ParentalLockRulesTests {
    @Test func pinMustBeFourDigits() {
        #expect(ParentalLockRules.isValidPin("0123"))
        #expect(!ParentalLockRules.isValidPin("123"))
        #expect(!ParentalLockRules.isValidPin("12345"))
        #expect(!ParentalLockRules.isValidPin("12a4"))
        #expect(!ParentalLockRules.isValidPin("١٢٣٤")) // non-ASCII digits
    }

    @Test func hashMatchesFlutterFormat() {
        // sha256("salt:1234"), lowercase hex, same as Dart's crypto package.
        #expect(ParentalLockRules.hashPin("1234", salt: "salt") == "35c56314f89066056408d6d269daf9e69217b9953215f286eec86cec3076271a")
        #expect(ParentalLockRules.hashPin("1234", salt: "a") != ParentalLockRules.hashPin("1234", salt: "b"))
        #expect(ParentalLockRules.hashPin("1234", salt: "a") == ParentalLockRules.hashPin("1234", salt: "a"))
    }

    @Test func saltIsRandomBase64URL() {
        let salt = ParentalLockRules.newSalt()
        #expect(salt != ParentalLockRules.newSalt())
        #expect(!salt.contains("+") && !salt.contains("/"))
        #expect(salt.count == 24)
    }

    @Test func hiddenOnlyWithPinAndNotForAll() {
        let locked: Set = ["7"]
        #expect(ParentalLockRules.isHidden(hasPin: true, lockedIDs: locked, unlockedIDs: [], categoryID: "7"))
        #expect(!ParentalLockRules.isHidden(hasPin: false, lockedIDs: locked, unlockedIDs: [], categoryID: "7"))
        #expect(!ParentalLockRules.isHidden(hasPin: true, lockedIDs: locked, unlockedIDs: ["7"], categoryID: "7"))
        #expect(!ParentalLockRules.isHidden(hasPin: true, lockedIDs: [""], unlockedIDs: [], categoryID: ""))
        #expect(!ParentalLockRules.isHidden(hasPin: true, lockedIDs: locked, unlockedIDs: [], categoryID: "8"))
    }

    @Test func settingsSearchSkipsAllAndMatchesCaseInsensitively() {
        let list = [Category.all, Category(id: "1", name: "Adult XXX"), Category(id: "2", name: "Kids")]
        #expect(ParentalLockViewModel.filter(list, query: "").map(\.id) == ["1", "2"])
        #expect(ParentalLockViewModel.filter(list, query: " xxx ").map(\.id) == ["1"])
    }
}

@MainActor
struct ParentalLockServiceTests {
    private func makeService(clock: @escaping () -> Date = { .now }) -> (ParentalLockService, InMemorySecureStore, Preferences) {
        let suite = "ParentalLockServiceTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        let store = InMemorySecureStore()
        let preferences = Preferences(defaults: defaults)
        return (ParentalLockService(store: store, preferences: preferences, profile: MockProfileRepository(), now: clock), store, preferences)
    }

    @Test func pinIsStoredHashedNotInPlainText() {
        let (lock, store, _) = makeService()
        lock.setPin("4321")
        #expect(lock.hasPin)
        #expect(store.string(for: .parentalPinHash) != "4321")
        #expect(lock.verifyPin("4321") == .ok)
        #expect(lock.verifyPin("0000") == .wrong)
    }

    @Test func fiveWrongTriesBlockForThirtySeconds() {
        var now = Date(timeIntervalSince1970: 1_000)
        let (lock, _, _) = makeService(clock: { now })
        lock.setPin("1111")
        for _ in 1..<ParentalLockRules.maxFailures {
            #expect(lock.verifyPin("2222") == .wrong)
        }
        #expect(lock.verifyPin("2222") == .blocked)
        // Even the right PIN is refused during the cooldown.
        #expect(lock.verifyPin("1111") == .blocked)
        now += 31
        #expect(lock.verifyPin("1111") == .ok)
    }

    @Test func locksPersistAndSurviveRemovingThePin() {
        let (lock, store, preferences) = makeService()
        lock.setPin("1234")
        lock.setCategoryLocked(.movies, categoryID: "9", locked: true)
        #expect(lock.isHidden(.movies, categoryID: "9"))
        #expect(!lock.isHidden(.series, categoryID: "9")) // ids are per type
        #expect(preferences.lockedCategoryIDs(for: .movies) == ["9"])

        let reveals = lock.revealCount
        lock.removePin()
        #expect(!lock.isHidden(.movies, categoryID: "9"))
        #expect(lock.isCategoryLocked(.movies, categoryID: "9"))
        #expect(lock.revealCount == reveals + 1)

        // A fresh service (next launch) reads the same locks back.
        let again = ParentalLockService(store: store, preferences: preferences, profile: MockProfileRepository())
        #expect(again.isCategoryLocked(.movies, categoryID: "9"))
    }

    @Test func unlockingOpensOnlyThatCategoryUntilRelock() async {
        let (lock, _, _) = makeService()
        lock.setPin("1234")
        lock.setCategoryLocked(.channels, categoryID: "1", locked: true)
        lock.setCategoryLocked(.channels, categoryID: "2", locked: true)

        async let opened = lock.guardCategory(.channels, categoryID: "1")
        await waitForPrompt(lock)
        #expect(lock.verifyPin("1234") == .ok)
        lock.finishPrompt(.verified)
        #expect(await opened)

        #expect(!lock.isHidden(.channels, categoryID: "1"))
        #expect(lock.isHidden(.channels, categoryID: "2"))
        lock.relock()
        #expect(lock.isHidden(.channels, categoryID: "1"))
    }

    @Test func cancellingThePadKeepsCategoryLocked() async {
        let (lock, _, _) = makeService()
        lock.setPin("1234")
        lock.setCategoryLocked(.series, categoryID: "3", locked: true)
        async let opened = lock.guardCategory(.series, categoryID: "3")
        await waitForPrompt(lock)
        lock.finishPrompt(.cancelled)
        #expect(await opened == false)
        #expect(lock.isHidden(.series, categoryID: "3"))
    }

    @Test func forgotPinNeedsTheAccountPassword() async {
        let (lock, _, _) = makeService()
        lock.setPin("1234")
        #expect(await lock.resetPin(withAccountPassword: "nope") == "Wrong password.")
        #expect(lock.hasPin)
        #expect(await lock.resetPin(withAccountPassword: "password") == nil)
        #expect(!lock.hasPin)
    }

    @Test func padCreateFlowNeedsMatchingPins() async {
        let (lock, _, _) = makeService()
        async let chosen = lock.chooseNewPin()
        await waitForPrompt(lock)
        let pad = PinPadViewModel(prompt: lock.prompt!, lock: lock)
        [1, 2, 3, 4].forEach(pad.add)
        #expect(pad.title == "Enter the PIN again")
        [9, 9, 9, 9].forEach(pad.add)
        #expect(pad.errorMessage == "PINs don't match, try again.")
        [1, 2, 3, 4].forEach(pad.add)
        #expect(await chosen)
        #expect(lock.verifyPin("1234") == .ok)
    }

    @Test func catalogHidesLockedItemsFromAllAndLeavesLockedCategory() async {
        let (lock, _, _) = makeService()
        let viewModel = CatalogViewModel<Channel>(type: .channels, repository: MockCatalogRepository(), parentalLock: lock)
        await viewModel.loadIfNeeded()
        #expect(viewModel.items.contains { $0.categoryId == "2" })

        lock.setPin("1234")
        lock.setCategoryLocked(.channels, categoryID: "2", locked: true)
        await viewModel.applyParentalLockChanges()
        #expect(!viewModel.items.contains { $0.categoryId == "2" })
        #expect(viewModel.isLocked(Category(id: "2", name: "")))

        // Unlocking reveals: the grid reloads and the items come back.
        lock.setCategoryLocked(.channels, categoryID: "2", locked: false)
        await viewModel.applyParentalLockChanges()
        #expect(viewModel.items.contains { $0.categoryId == "2" })
    }

    /// `guardCategory` / `chooseNewPin` publish the prompt before suspending.
    private func waitForPrompt(_ lock: ParentalLockService) async {
        for _ in 0..<100 where lock.prompt == nil {
            await Task.yield()
        }
    }
}

struct ParentalLockPremiumTests {
    @Test func paidPremiumOpensSettings() {
        #expect(ParentalLockRules.premiumBlockMessage(hasPin: false, isPremium: true, isFreeTrial: false) == nil)
    }

    @Test func freeTrialIsBlockedWithExplanation() {
        let message = ParentalLockRules.premiumBlockMessage(hasPin: false, isPremium: true, isFreeTrial: true)
        #expect(message?.contains("isn't part of the free trial") == true)
    }

    @Test func freeUserIsBlocked() {
        let message = ParentalLockRules.premiumBlockMessage(hasPin: false, isPremium: false, isFreeTrial: false)
        #expect(message?.contains("not included in the free trial") == true)
    }

    @Test func existingPinKeepsAccessAfterPremiumEnds() {
        #expect(ParentalLockRules.premiumBlockMessage(hasPin: true, isPremium: false, isFreeTrial: false) == nil)
    }
}
