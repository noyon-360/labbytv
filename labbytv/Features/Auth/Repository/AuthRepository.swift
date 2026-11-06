import Foundation

nonisolated protocol AuthRepository: Sendable {
    func login(email: String, password: String) async throws -> LoginResponse
    func register(_ request: RegisterRequest) async throws -> LoginResponse
    /// Emails a 6-digit OTP.
    func sendPasswordResetCode(email: String) async throws
    func resetPassword(email: String, otp: String, password: String) async throws
    func requestTVLoginCode(deviceName: String) async throws -> TVLoginCode
    func pollTVLogin(deviceCode: String) async throws -> TVLoginPollResult
}
