import Foundation

/// An audio or subtitle track. `id` is VLC's track index; `-1` means "off".
public struct VLCTrack: Identifiable, Hashable, Sendable {
    public let id: Int32
    public let name: String
}
