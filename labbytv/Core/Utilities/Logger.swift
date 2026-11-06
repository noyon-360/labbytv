import Foundation
import os

/// Shared loggers. Never interpolate passwords, tokens or IPTV credentials;
/// mark anything user-specific `privacy: .private`.
nonisolated extension Logger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.almightyflippa.labbytv"

    static let network = Logger(subsystem: subsystem, category: "network")
    static let auth = Logger(subsystem: subsystem, category: "auth")
    static let storage = Logger(subsystem: subsystem, category: "storage")
    static let player = Logger(subsystem: subsystem, category: "player")
    static let premium = Logger(subsystem: subsystem, category: "premium")
}
