import SwiftUI

/// Shows the PIN pad whenever `ParentalLockService` asks for it, so any
/// view model can `await lock.verifyParent()` like Flutter's `Get.dialog`.
struct PinPromptPresenter: ViewModifier {
    let lock: ParentalLockService

    func body(content: Content) -> some View {
        content.fullScreenCover(item: Binding(
            get: { lock.prompt },
            // Only Menu dismisses through the binding; the pad finishes the
            // prompt itself on success.
            set: { if $0 == nil { lock.finishPrompt(.cancelled) } }
        )) { prompt in
            PinPadView(viewModel: PinPadViewModel(prompt: prompt, lock: lock))
        }
    }
}

extension View {
    func pinPrompt(_ lock: ParentalLockService) -> some View {
        modifier(PinPromptPresenter(lock: lock))
    }
}
