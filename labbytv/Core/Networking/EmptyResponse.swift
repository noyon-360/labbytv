import Foundation

/// For endpoints whose `data` we don't use (forgot password, add playlist…).
/// Decodes from any JSON value, including `null`, `""` and `{}`.
nonisolated struct EmptyResponse: Decodable, Sendable {
    init() {}
    init(from decoder: any Decoder) throws {}
}
