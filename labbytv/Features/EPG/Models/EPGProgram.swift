import Foundation

/// One programme from `/epg/schedule`. Mirrors Flutter `EpgProgramModel`.
nonisolated struct EPGProgram: Decodable, Sendable, Hashable, Identifiable {
    let id: String
    let title: String
    let description: String
    let start: Date
    let end: Date

    init(id: String, title: String, description: String, start: Date, end: Date) {
        self.id = id
        self.title = title
        self.description = description
        self.start = start
        self.end = end
    }

    private enum CodingKeys: String, CodingKey {
        case id, title, description, start, end
        case startTimestamp = "start_timestamp"
        case stopTimestamp = "stop_timestamp"
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let title = Base64.decodedText(container.lenientString(.title) ?? "")
        self.title = title.trimmingCharacters(in: .whitespaces).isEmpty ? "Unknown Program" : title
        description = Base64.decodedText(container.lenientString(.description) ?? "")

        if let seconds = container.lenientInt(.startTimestamp) {
            start = Date(timeIntervalSince1970: TimeInterval(seconds))
        } else {
            start = Self.parseDate(container.lenientString(.start)) ?? .now
        }
        if let seconds = container.lenientInt(.stopTimestamp) {
            end = Date(timeIntervalSince1970: TimeInterval(seconds))
        } else {
            end = Self.parseDate(container.lenientString(.end)) ?? .now
        }
        let rawID = container.lenientString(.id) ?? ""
        // Some providers repeat ids; the start time keeps the key unique.
        id = "\(rawID)-\(Int(start.timeIntervalSince1970))"
    }

    func isAiring(at date: Date) -> Bool {
        start <= date && end > date
    }

    func progress(at date: Date) -> Double {
        let total = end.timeIntervalSince(start)
        guard total > 0 else { return 0 }
        return min(1, max(0, date.timeIntervalSince(start) / total))
    }

    /// Xtream `start`/`end` strings are "yyyy-MM-dd HH:mm:ss" in UTC.
    private static func parseDate(_ string: String?) -> Date? {
        guard let string else { return nil }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "UTC")
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.date(from: string)
    }
}
