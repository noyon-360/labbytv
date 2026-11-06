import Foundation
import Observation
import os

/// Parental lock: a 4-digit PIN guards the categories a parent picks.
/// Entering the PIN opens only the category asked for, and every unlock ends
/// when the app goes to the background. Mirrors Flutter `ParentalLockService`
/// (no biometrics: Apple TV has no Face ID / Touch ID).
///
/// The PIN hash lives in the Keychain and the locked category ids in
/// `Preferences`. Both survive sign-out, as in the Flutter app: the lock
/// belongs to the device, not the account.
@MainActor
@Observable
final class ParentalLockService {
    private(set) var hasPin: Bool
    private(set) var lockedIDs: [ContentType: Set<String>]
    private(set) var unlockedIDs: [ContentType: Set<String>] = [:]

    /// Bumped whenever what should be hidden changes, so lists update right away.
    private(set) var changeCount = 0
    /// Bumped when a change reveals something. Hiding only needs a filter;
    /// revealing needs a reload, because filtered-out items are gone.
    private(set) var revealCount = 0

    /// The PIN pad request currently on screen.
    private(set) var prompt: PinPrompt?

    @ObservationIgnored private let store: any SecureStore
    @ObservationIgnored private let preferences: Preferences
    @ObservationIgnored private let profile: any ProfileRepository
    @ObservationIgnored private let now: () -> Date
    @ObservationIgnored private var failures = 0
    @ObservationIgnored private var blockedUntil: Date?
    @ObservationIgnored private var continuation: CheckedContinuation<PinPromptResult, Never>?

    init(store: any SecureStore, preferences: Preferences, profile: any ProfileRepository, now: @escaping () -> Date = { .now }) {
        self.store = store
        self.preferences = preferences
        self.profile = profile
        self.now = now
        hasPin = store.string(for: .parentalPinHash) != nil && store.string(for: .parentalPinSalt) != nil
        lockedIDs = Dictionary(uniqueKeysWithValues: ContentType.allCases.map { ($0, preferences.lockedCategoryIDs(for: $0)) })
    }

    // MARK: Queries

    func isHidden(_ type: ContentType, categoryID: String) -> Bool {
        ParentalLockRules.isHidden(
            hasPin: hasPin,
            lockedIDs: lockedIDs[type] ?? [],
            unlockedIDs: unlockedIDs[type] ?? [],
            categoryID: categoryID
        )
    }

    /// For the settings list: locked, whether or not a PIN is set.
    func isCategoryLocked(_ type: ContentType, categoryID: String) -> Bool {
        lockedIDs[type]?.contains(categoryID) ?? false
    }

    // MARK: Locks

    func setCategoryLocked(_ type: ContentType, categoryID: String, locked: Bool) {
        var ids = lockedIDs[type] ?? []
        if locked {
            ids.insert(categoryID)
            // Locking a category opened earlier this session hides it now too.
            unlockedIDs[type]?.remove(categoryID)
        } else {
            ids.remove(categoryID)
        }
        lockedIDs[type] = ids
        preferences.setLockedCategoryIDs(ids, for: type)
        notify(reveals: !locked)
    }

    /// True when the category may be opened now, asking for the PIN first if it's locked.
    func guardCategory(_ type: ContentType, categoryID: String) async -> Bool {
        guard isHidden(type, categoryID: categoryID) else { return true }
        guard await verifyParent(subtitle: "This category is locked.") else { return false }
        // Only this category opens; other locked ones stay hidden. No
        // notify, as in Flutter: other lists keep filtering until they reload.
        unlockedIDs[type, default: []].insert(categoryID)
        return true
    }

    /// Asks for the PIN. Unlocks nothing by itself: opening the settings
    /// screen must not make locked content visible.
    func verifyParent(subtitle: String? = nil) async -> Bool {
        guard hasPin else { return true }
        return await requestPin(PinPrompt(kind: .verify, subtitle: subtitle)) == .verified
    }

    /// Shows the "choose a PIN" pad and saves the result. False when cancelled.
    func chooseNewPin() async -> Bool {
        guard case .created(let pin) = await requestPin(PinPrompt(kind: .create, subtitle: nil)) else {
            return false
        }
        setPin(pin)
        return true
    }

    /// Ends every unlock of this session. Called when the app is backgrounded.
    func relock() {
        guard unlockedIDs.values.contains(where: { !$0.isEmpty }) else { return }
        unlockedIDs = [:]
        notify(reveals: false)
    }

    // MARK: PIN

    func verifyPin(_ pin: String) -> PinCheck {
        if let blockedUntil, now() < blockedUntil {
            return .blocked
        }
        if let hash = store.string(for: .parentalPinHash),
           let salt = store.string(for: .parentalPinSalt),
           ParentalLockRules.hashPin(pin, salt: salt) == hash {
            failures = 0
            blockedUntil = nil
            return .ok
        }
        // A 4-digit PIN is easy to brute force by clicking, so slow that down.
        failures += 1
        if failures >= ParentalLockRules.maxFailures {
            failures = 0
            blockedUntil = now().addingTimeInterval(TimeInterval(ParentalLockRules.cooldown.components.seconds))
            return .blocked
        }
        return .wrong
    }

    func setPin(_ pin: String) {
        guard ParentalLockRules.isValidPin(pin) else { return }
        let salt = ParentalLockRules.newSalt()
        store.set(salt, for: .parentalPinSalt)
        store.set(ParentalLockRules.hashPin(pin, salt: salt), for: .parentalPinHash)
        hasPin = true
        notify(reveals: false)
    }

    /// Turns the lock off. Locked categories are kept, so setting a new PIN
    /// later brings the same locks back.
    func removePin() {
        store.remove(.parentalPinHash)
        store.remove(.parentalPinSalt)
        hasPin = false
        unlockedIDs = [:]
        failures = 0
        blockedUntil = nil
        notify(reveals: true)
    }

    /// "Forgot PIN?": the account password belongs to the parent, so it's
    /// enough to remove the PIN. Returns an error to show, or nil on success.
    func resetPin(withAccountPassword password: String) async -> String? {
        do {
            guard try await profile.verifyPassword(password) else { return "Wrong password." }
        } catch APIError.server(status: 404, _) {
            return "Not available yet. Please update the app later."
        } catch {
            Logger.auth.error("Parental lock: password check failed")
            return "Could not check the password. Check your connection."
        }
        removePin()
        return nil
    }

    // MARK: Prompt plumbing

    /// Shows the PIN pad and waits for it to finish.
    func requestPin(_ request: PinPrompt) async -> PinPromptResult {
        // Only one pad at a time; a new request cancels the old one.
        finishPrompt(.cancelled)
        prompt = request
        return await withCheckedContinuation { continuation = $0 }
    }

    /// Called by the PIN pad (and when Menu dismisses it).
    func finishPrompt(_ result: PinPromptResult) {
        prompt = nil
        let pending = continuation
        continuation = nil
        pending?.resume(returning: result)
    }

    private func notify(reveals: Bool) {
        changeCount += 1
        if reveals { revealCount += 1 }
    }
}
