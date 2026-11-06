import Foundation

nonisolated enum DateFormatting {
    /// "9:30 PM" in the viewer's locale and time zone.
    static func time(_ date: Date) -> String {
        date.formatted(date: .omitted, time: .shortened)
    }

    static func timeRange(_ start: Date, _ end: Date) -> String {
        "\(time(start)) – \(time(end))"
    }

    /// EPG and the backend use Unix seconds (UTC).
    static func unixSeconds(_ date: Date) -> Int {
        Int(date.timeIntervalSince1970)
    }

    /// Floors to the previous half hour, for the guide's time ruler.
    static func floorToHalfHour(_ date: Date) -> Date {
        let seconds = date.timeIntervalSince1970
        return Date(timeIntervalSince1970: (seconds / 1800).rounded(.down) * 1800)
    }

    /// "1h 52m" from seconds.
    static func duration(seconds: Int) -> String {
        guard seconds > 0 else { return "" }
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        return hours > 0 ? "\(hours)h \(minutes)m" : "\(minutes)m"
    }
}
