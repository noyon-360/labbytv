import Foundation

/// The backend envelope: `{ success | status, message, data, errorSources }`.
/// Watch-history endpoints use `status` instead of `success`.
nonisolated struct APIResponse<T: Decodable>: Decodable {
    let success: Bool
    let message: String
    let data: T?
    let errorSources: [ErrorSource]

    nonisolated struct ErrorSource: Decodable, Sendable {
        let path: String?
        let message: String?
    }

    private enum CodingKeys: String, CodingKey {
        case success, status, message, data, errorSources
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        success = try container.decodeIfPresent(Bool.self, forKey: .success)
            ?? container.decodeIfPresent(Bool.self, forKey: .status)
            ?? false
        message = try container.decodeIfPresent(String.self, forKey: .message) ?? ""
        errorSources = try container.decodeIfPresent([ErrorSource].self, forKey: .errorSources) ?? []
        // Failure responses put unrelated shapes in `data` (e.g. login's
        // unverified-OTP 403 sends `{ email }`), so only decode it on success.
        data = success ? try container.decodeIfPresent(T.self, forKey: .data) : nil
    }

    /// Validation errors list each field; fall back to the top-level message.
    var errorMessage: String {
        let details = errorSources.compactMap(\.message).filter { !$0.isEmpty }
        return details.isEmpty ? message : details.joined(separator: "\n")
    }
}
