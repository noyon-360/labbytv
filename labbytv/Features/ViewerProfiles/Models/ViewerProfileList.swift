import Foundation

/// `GET /profiles`: the account's profiles (main one first) and the limit.
nonisolated struct ViewerProfileList: Decodable, Sendable {
    let profiles: [ViewerProfile]
    let maxProfiles: Int

    init(profiles: [ViewerProfile], maxProfiles: Int = 5) {
        self.profiles = profiles
        self.maxProfiles = maxProfiles
    }

    private enum CodingKeys: String, CodingKey {
        case profiles, maxProfiles
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        profiles = ((try? container.decodeIfPresent(LossyArray<ViewerProfile>.self, forKey: .profiles))?.elements ?? [])
            .filter { !$0.id.isEmpty }
        maxProfiles = container.lenientInt(.maxProfiles) ?? 5
    }
}
