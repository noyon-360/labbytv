import Foundation

/// `data` of `/auth/tv/poll`: `{ status, …login fields when approved }`.
nonisolated struct TVLoginPollResult: Decodable, Sendable {
    nonisolated enum Status: String, Sendable {
        case pending, approved, denied, expired
    }

    let status: Status
    let login: LoginResponse?

    private enum CodingKeys: String, CodingKey {
        case status
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let raw = container.lenientString(.status) ?? ""
        let parsed = Status(rawValue: raw) ?? .pending
        if parsed == .approved {
            let login = try? LoginResponse(from: decoder)
            // "Approved" without tokens can't sign in; treat it as pending
            // so the next poll tries again (same as Flutter).
            if let token = login?.accessToken, !token.isEmpty {
                status = .approved
                self.login = login
                return
            }
            status = .pending
            self.login = nil
            return
        }
        status = parsed
        login = nil
    }
}
