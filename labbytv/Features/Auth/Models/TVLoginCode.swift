import Foundation

/// `data` of `/auth/tv/code`. Mirrors Flutter `TvLoginCode`.
nonisolated struct TVLoginCode: Decodable, Sendable, Equatable {
    /// Secret the TV polls with. Never shown on screen or logged.
    let deviceCode: String
    let userCode: String
    let expiresIn: Int
    let interval: Int

    /// `labbytv://tv-login?code=…`, read by the phone app's scanner.
    var qrPayload: String { "labbytv://tv-login?code=\(userCode)" }

    /// `K7PQ4XMZ` → `K7PQ-4XMZ`, easier to read across the room.
    var displayCode: String {
        guard userCode.count == 8 else { return userCode }
        return "\(userCode.prefix(4))-\(userCode.suffix(4))"
    }

    init(deviceCode: String, userCode: String, expiresIn: Int, interval: Int) {
        self.deviceCode = deviceCode
        self.userCode = userCode
        self.expiresIn = expiresIn
        self.interval = interval
    }

    private enum CodingKeys: String, CodingKey {
        case deviceCode, userCode, expiresIn, interval
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        deviceCode = container.lenientString(.deviceCode) ?? ""
        userCode = container.lenientString(.userCode) ?? ""
        expiresIn = container.lenientInt(.expiresIn) ?? 600
        // Never poll faster than every 2 s, whatever the server says.
        interval = min(30, max(2, container.lenientInt(.interval) ?? 5))
    }
}
