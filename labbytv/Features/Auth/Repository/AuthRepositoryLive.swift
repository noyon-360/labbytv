import Foundation

nonisolated struct AuthRepositoryLive: AuthRepository {
    let client: APIClient
    let store: any SecureStore

    func login(email: String, password: String) async throws -> LoginResponse {
        let request = LoginRequest(email: email, password: password, deviceId: store.deviceID())
        return try await client.post(.login, body: request)
    }

    /// The backend returns the new user document, which carries
    /// `accessToken`/`refreshToken`/`role`/`_id` like a login response.
    func register(_ request: RegisterRequest) async throws -> LoginResponse {
        try await client.post(.register, body: request)
    }

    func sendPasswordResetCode(email: String) async throws {
        let _: EmptyResponse = try await client.post(.forgotPassword, body: ["email": email])
    }

    /// The backend compares the OTP as a string (`!==`), so never send it as a number.
    func resetPassword(email: String, otp: String, password: String) async throws {
        let body = ["email": email, "otp": otp, "password": password]
        let _: EmptyResponse = try await client.post(.resetPassword, body: body)
    }

    func requestTVLoginCode(deviceName: String) async throws -> TVLoginCode {
        let body = ["deviceId": store.deviceID(), "deviceName": deviceName]
        return try await client.post(.tvCode, body: body)
    }

    func pollTVLogin(deviceCode: String) async throws -> TVLoginPollResult {
        try await client.post(.tvPoll, body: ["deviceCode": deviceCode])
    }
}
