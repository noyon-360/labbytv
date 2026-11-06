import Foundation
import Observation

@MainActor
@Observable
final class RegisterViewModel {
    var name = ""
    var email = ""
    var password = ""
    var confirmPassword = ""
    var agreedToTerms = false
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    @ObservationIgnored private let repository: any AuthRepository
    @ObservationIgnored private let session: SessionStore
    @ObservationIgnored private let onSignedIn: @MainActor () async -> Void

    init(repository: any AuthRepository, session: SessionStore, onSignedIn: @escaping @MainActor () async -> Void = {}) {
        self.repository = repository
        self.session = session
        self.onSignedIn = onSignedIn
    }

    func register() async {
        guard !isLoading else { return }
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        if let message = Self.validationMessage(name: trimmedName, email: trimmedEmail, password: password, confirmPassword: confirmPassword, agreedToTerms: agreedToTerms) {
            errorMessage = message
            return
        }

        errorMessage = nil
        isLoading = true
        defer { isLoading = false }
        do {
            let request = RegisterRequest(name: trimmedName, email: trimmedEmail, password: password, confirmPassword: confirmPassword)
            let response = try await repository.register(request)
            try session.signIn(with: response)
            await onSignedIn()
        } catch is CancellationError {
            return
        } catch {
            errorMessage = (error as? APIError)?.userMessage ?? APIError.unknown.userMessage
        }
    }

    /// Password strength is checked by the backend, which replies with a message.
    nonisolated static func validationMessage(name: String, email: String, password: String, confirmPassword: String, agreedToTerms: Bool) -> String? {
        if name.isEmpty { return "Name is required" }
        if let message = LoginViewModel.validationMessage(email: email, password: password) { return message }
        if password != confirmPassword { return "Passwords don't match" }
        if !agreedToTerms { return "Please agree to Terms & Conditions" }
        return nil
    }
}
