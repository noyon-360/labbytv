import Foundation
import Observation

/// Email → 6-digit OTP → new password, same flow as the Flutter app.
@MainActor
@Observable
final class ForgotPasswordViewModel {
    enum Step: Equatable {
        case enterEmail
        case enterCode
        case done
    }

    var email: String
    var otp = ""
    var password = ""
    var confirmPassword = ""
    private(set) var step: Step = .enterEmail
    private(set) var isLoading = false
    private(set) var errorMessage: String?
    private(set) var infoMessage: String?

    @ObservationIgnored private let repository: any AuthRepository

    init(repository: any AuthRepository, initialEmail: String = "") {
        self.repository = repository
        self.email = initialEmail.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func sendCode() async {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard LoginViewModel.isValidEmail(trimmed) else {
            errorMessage = trimmed.isEmpty ? "Email is required" : "Enter a valid email address"
            return
        }
        await perform {
            try await self.repository.sendPasswordResetCode(email: trimmed)
            self.email = trimmed
            self.step = .enterCode
            self.infoMessage = "We emailed a 6-digit code to \(trimmed)."
        }
    }

    func resetPassword() async {
        let code = otp.filter(\.isNumber)
        if let message = Self.validationMessage(otp: code, password: password, confirmPassword: confirmPassword) {
            errorMessage = message
            return
        }
        await perform {
            try await self.repository.resetPassword(email: self.email, otp: code, password: self.password)
            self.step = .done
            self.infoMessage = "Your password has been reset. Sign in with your new password."
        }
    }

    nonisolated static func validationMessage(otp: String, password: String, confirmPassword: String) -> String? {
        if otp.count != 6 { return "Enter the 6-digit code from the email" }
        if password.isEmpty { return "Password is required" }
        if password != confirmPassword { return "Passwords don't match" }
        return nil
    }

    private func perform(_ work: @escaping @MainActor () async throws -> Void) async {
        guard !isLoading else { return }
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }
        do {
            try await work()
        } catch is CancellationError {
            return
        } catch {
            errorMessage = (error as? APIError)?.userMessage ?? APIError.unknown.userMessage
        }
    }
}
