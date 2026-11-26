import Foundation

/// What happens when the main app opens (app start, sign-in, or a profile
/// was deleted elsewhere). Same rules as Flutter `decideProfileStart`.
nonisolated enum ProfileStart: Equatable, Sendable {
    /// Show "Who's Watching".
    case picker
    /// Go straight in with this profile (`nil`: the backend's main profile,
    /// e.g. when the list is empty).
    case use(ViewerProfile?)

    /// One profile: never ask. Several: ask at app start (`askWhenSeveral`,
    /// with the last one highlighted), or when this device hasn't chosen one
    /// yet or the chosen one is gone.
    static func decide(profiles: [ViewerProfile], lastProfileID: String?, askWhenSeveral: Bool) -> ProfileStart {
        guard !profiles.isEmpty else { return .use(nil) }
        let last = profiles.first { $0.id == lastProfileID }
        if profiles.count > 1 && (askWhenSeveral || last == nil) {
            return .picker
        }
        return .use(last ?? profiles.first(where: \.isDefault) ?? profiles[0])
    }
}
