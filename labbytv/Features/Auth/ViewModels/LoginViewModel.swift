import Foundation
import Observation
import os

@MainActor
@Observable
final class LoginViewModel {
    var email = ""
    var password = ""
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

    func login() async {
        guard !isLoading else { return }
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)

        if let message = Self.validationMessage(email: trimmedEmail, password: password) {
            errorMessage = message
            return
        }

        errorMessage = nil
        isLoading = true
        defer { isLoading = false }

        do {
            let response = try await repository.login(email: trimmedEmail, password: password)
            try session.signIn(with: response)
            Logger.auth.info("Signed in")
            await onSignedIn()
        } catch is CancellationError {
            return
        } catch let error as APIError {
            errorMessage = error.userMessage
        } catch {
            errorMessage = APIError.unknown.userMessage
        }
    }

    func clearError() {
        errorMessage = nil
    }

    /// Same rules as the Flutter login form: a valid email, a non-empty password.
    nonisolated static func validationMessage(email: String, password: String) -> String? {
        if email.isEmpty { return "Email is required" }
        if !isValidEmail(email) { return "Enter a valid email address" }
        if password.isEmpty { return "Password is required" }
        return nil
    }

    nonisolated static func isValidEmail(_ email: String) -> Bool {
        email.wholeMatch(of: /[^@\s]+@[^@\s]+\.[^@\s]+/) != nil
    }
}
