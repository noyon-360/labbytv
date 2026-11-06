import Foundation

/// `data` of `/server/get-play-url`: `{ data: <Xtream info>, playUrl }`.
/// Live streams get `data: {}`; movies and series get the provider's
/// `get_vod_info` / `get_series_info` payload, decoded as `Info`.
nonisolated struct PlayURLResponse<Info: Decodable & Sendable>: Decodable, Sendable {
    let info: Info?
    let playUrl: String

    private enum CodingKeys: String, CodingKey {
        case data, playUrl
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        info = try? container.decodeIfPresent(Info.self, forKey: .data)
        playUrl = container.lenientString(.playUrl) ?? ""
    }
}
