import Foundation

/// Decodes a JSON array but drops elements that fail, so one malformed
/// channel can't blank the whole page.
nonisolated struct LossyArray<Element: Decodable>: Decodable {
    let elements: [Element]

    init(from decoder: any Decoder) throws {
        var container = try decoder.unkeyedContainer()
        var result: [Element] = []
        while !container.isAtEnd {
            if let element = try? container.decode(Element.self) {
                result.append(element)
            } else {
                _ = try? container.decode(DiscardedValue.self)
            }
        }
        elements = result
    }

    private struct DiscardedValue: Decodable {
        init(from decoder: any Decoder) throws {}
    }
}

extension LossyArray: Sendable where Element: Sendable {}
