import Foundation

nonisolated enum Base64 {
    /// Xtream EPG titles and descriptions are base64 UTF-8. Some providers
    /// send plain text instead, so fall back to the input (as Flutter does).
    static func decodedText(_ value: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "" }
        var padded = trimmed
        let remainder = padded.count % 4
        if remainder > 0 { padded += String(repeating: "=", count: 4 - remainder) }
        guard let data = Data(base64Encoded: padded),
              let text = String(data: data, encoding: .utf8) else {
            return trimmed
        }
        return text
    }
}
