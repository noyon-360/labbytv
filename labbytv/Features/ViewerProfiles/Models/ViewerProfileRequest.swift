import Foundation

/// Body for `POST /profiles` and `PATCH /profiles/:id`. `nil` fields are left
/// out, so a PATCH only changes what was sent.
nonisolated struct ViewerProfileRequest: Encodable, Sendable {
    var name: String?
    var avatar: String?
}
