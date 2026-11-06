import Foundation

/// EPG is fetched one channel per request, so cache per channel and share
/// in-flight requests (several rows can ask for the same channel while
/// scrolling back and forth).
actor EPGCache {
    private struct Entry {
        let from: Date
        let to: Date
        let fetchedAt: Date
        let programs: [EPGProgram]
    }

    private let repository: any EPGRepository
    private let lifetime: TimeInterval
    private var entries: [Int: Entry] = [:]
    private var inFlight: [Int: Task<[EPGProgram], Error>] = [:]

    init(repository: any EPGRepository, lifetime: TimeInterval = 300) {
        self.repository = repository
        self.lifetime = lifetime
    }

    func programs(channelID: Int, from: Date, to: Date) async throws -> [EPGProgram] {
        if let entry = entries[channelID],
           entry.from <= from, entry.to >= to,
           Date.now.timeIntervalSince(entry.fetchedAt) < lifetime {
            return entry.programs.filter { $0.end > from && $0.start < to }
        }
        if let task = inFlight[channelID] {
            return try await task.value.filter { $0.end > from && $0.start < to }
        }
        let repository = repository
        let task = Task { try await repository.schedule(channelID: channelID, from: from, to: to) }
        inFlight[channelID] = task
        defer { inFlight[channelID] = nil }
        let programs = try await task.value
        entries[channelID] = Entry(from: from, to: to, fetchedAt: .now, programs: programs)
        return programs
    }

    func clear() {
        entries.removeAll()
    }
}
