import Testing
@testable import labbytv

struct ValidationTests {
    @Test func loginValidation() {
        #expect(LoginViewModel.validationMessage(email: "", password: "x") == "Email is required")
        #expect(LoginViewModel.validationMessage(email: "nope", password: "x") == "Enter a valid email address")
        #expect(LoginViewModel.validationMessage(email: "a@b.co", password: "") == "Password is required")
        #expect(LoginViewModel.validationMessage(email: "a@b.co", password: "x") == nil)
    }

    @Test func registerValidation() {
        #expect(RegisterViewModel.validationMessage(name: "A", email: "a@b.co", password: "x", confirmPassword: "y", agreedToTerms: true) == "Passwords don't match")
        #expect(RegisterViewModel.validationMessage(name: "A", email: "a@b.co", password: "x", confirmPassword: "x", agreedToTerms: false) == "Please agree to Terms & Conditions")
    }

    @Test func otpMustBeSixDigits() {
        #expect(ForgotPasswordViewModel.validationMessage(otp: "123", password: "x", confirmPassword: "x") != nil)
        #expect(ForgotPasswordViewModel.validationMessage(otp: "123456", password: "x", confirmPassword: "x") == nil)
    }

    @Test func playlistURLNormalisation() {
        #expect(AddPlaylistViewModel.normalizedURL(" example.com:8080/ ") == "http://example.com:8080")
        #expect(AddPlaylistViewModel.normalizedURL("https://a.tv") == "https://a.tv")
    }

    @Test func tvCodeDisplay() {
        let code = TVLoginCode(deviceCode: "d", userCode: "K7PQ4XMZ", expiresIn: 600, interval: 5)
        #expect(code.displayCode == "K7PQ-4XMZ")
        #expect(code.qrPayload == "labbytv://tv-login?code=K7PQ4XMZ")
    }
}
