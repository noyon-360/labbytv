import Foundation
import Observation

/// State of the on-screen PIN pad. The Siri Remote has no number keys, so
/// digits are entered on a focusable keypad (Flutter `pin_pad_dialog.dart`).
@MainActor
@Observable
final class PinPadViewModel {
    enum Mode: Equatable {
        case pin
        /// "Forgot PIN?": the account password removes the PIN.
        case password
        /// PIN removed with the password; confirm before continuing.
        case removed
    }

    let prompt: PinPrompt
    private(set) var mode: Mode = .pin
    private(set) var entered = ""
    private(set) var errorMessage: String?
    private(set) var isChecking = false
    var password = ""

    /// Create flow: the first entry, waiting to be confirmed.
    @ObservationIgnored private var firstPin: String?
    @ObservationIgnored private let lock: ParentalLockService

    init(prompt: PinPrompt, lock: ParentalLockService) {
        self.prompt = prompt
        self.lock = lock
    }

    var pinLength: Int { ParentalLockRules.pinLength }
    var showsForgot: Bool { prompt.kind == .verify }

    var title: String {
        switch prompt.kind {
        case .verify: "Enter parental PIN"
        case .create: firstPin == nil ? "Choose a 4-digit PIN" : "Enter the PIN again"
        }
    }

    func add(_ digit: Int) {
        guard mode == .pin, entered.count < pinLength, (0...9).contains(digit) else { return }
        entered.append(String(digit))
        errorMessage = nil
        if entered.count == pinLength {
            submit()
        }
    }

    func deleteLast() {
        guard !entered.isEmpty else { return }
        entered.removeLast()
    }

    func cancel() {
        lock.finishPrompt(.cancelled)
    }

    func showForgot() {
        password = ""
        errorMessage = nil
        mode = .password
    }

    func backToPin() {
        errorMessage = nil
        mode = .pin
    }

    func resetWithPassword() async {
        guard !password.isEmpty, !isChecking else { return }
        isChecking = true
        defer { isChecking = false }
        if let error = await lock.resetPin(withAccountPassword: password) {
            errorMessage = error
        } else {
            password = ""
            errorMessage = nil
            mode = .removed
        }
    }

    /// After "PIN removed": the parent proved who they are, so continue.
    func continueAfterRemoval() {
        lock.finishPrompt(.verified)
    }

    private func submit() {
        let pin = entered
        entered = ""
        switch prompt.kind {
        case .verify:
            switch lock.verifyPin(pin) {
            case .ok:
                lock.finishPrompt(.verified)
            case .wrong:
                errorMessage = "Wrong PIN, try again."
            case .blocked:
                errorMessage = "Too many tries. Wait \(ParentalLockRules.cooldown.components.seconds) seconds."
            }
        case .create:
            guard let firstPin else {
                firstPin = pin
                return
            }
            if pin == firstPin {
                lock.finishPrompt(.created(pin: pin))
            } else {
                errorMessage = "PINs don't match, try again."
            }
        }
    }
}
