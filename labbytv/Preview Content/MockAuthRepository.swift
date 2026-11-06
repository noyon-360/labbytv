#if DEBUG
import Foundation

nonisolated struct MockAuthRepository: AuthRepository {
    var result: Result<LoginResponse, APIError> = .success(MockData.loginResponse)
    var delay: Duration = .seconds(1)

    func login(email: String, password: String) async throws -> LoginResponse {
        try await Task.sleep(for: delay)
        return try result.get()
    }

    func register(_ request: RegisterRequest) async throws -> LoginResponse {
        try await Task.sleep(for: delay)
        return try result.get()
    }

    func sendPasswordResetCode(email: String) async throws {
        try await Task.sleep(for: delay)
    }

    func resetPassword(email: String, otp: String, password: String) async throws {
        try await Task.sleep(for: delay)
    }

    func requestTVLoginCode(deviceName: String) async throws -> TVLoginCode {
        TVLoginCode(deviceCode: "preview", userCode: "K7PQ4XMZ", expiresIn: 600, interval: 5)
    }

    func pollTVLogin(deviceCode: String) async throws -> TVLoginPollResult {
        try await Task.sleep(for: .seconds(3600))
        throw CancellationError()
    }
}
#endif
