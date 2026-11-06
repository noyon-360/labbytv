import Foundation

/// Channel up/down within the current category, wrapping at both ends.
nonisolated enum ChannelSwitcher {
    static func channel(from current: Channel, in lineup: [Channel], offset: Int) -> Channel? {
        guard !lineup.isEmpty, let index = lineup.firstIndex(where: { $0.id == current.id }) else {
            return nil
        }
        let count = lineup.count
        let next = ((index + offset) % count + count) % count
        return next == index ? nil : lineup[next]
    }
}
