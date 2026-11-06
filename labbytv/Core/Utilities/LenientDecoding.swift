import Foundation

/// Xtream providers send the same field as a number on one server and a
/// string on another (`"stream_id": "123"` vs `123`, `"rating": ""`), and
/// sometimes `null`. These helpers never throw on a type mismatch; they
/// mirror the Flutter `_parseInt` / `toString()` fallbacks.
nonisolated extension KeyedDecodingContainer {
    func lenientInt(_ key: Key) -> Int? {
        if let value = try? decodeIfPresent(Int.self, forKey: key) { return value }
        if let value = try? decodeIfPresent(Double.self, forKey: key) { return Int(value) }
        if let value = try? decodeIfPresent(String.self, forKey: key) {
            return Int(value.trimmingCharacters(in: .whitespaces))
                ?? Double(value).map { Int($0) }
        }
        return nil
    }

    func lenientDouble(_ key: Key) -> Double? {
        if let value = try? decodeIfPresent(Double.self, forKey: key) { return value }
        if let value = try? decodeIfPresent(String.self, forKey: key) { return Double(value) }
        return nil
    }

    func lenientString(_ key: Key) -> String? {
        if let value = try? decodeIfPresent(String.self, forKey: key) { return value }
        if let value = try? decodeIfPresent(Int.self, forKey: key) { return String(value) }
        if let value = try? decodeIfPresent(Double.self, forKey: key) { return String(value) }
        return nil
    }

    func lenientBool(_ key: Key) -> Bool? {
        if let value = try? decodeIfPresent(Bool.self, forKey: key) { return value }
        if let value = lenientInt(key) { return value != 0 }
        return nil
    }

    /// `category_ids` is an array of ints or numeric strings.
    func lenientIntArray(_ key: Key) -> [Int] {
        if let values = try? decodeIfPresent([Int].self, forKey: key) { return values }
        if let values = try? decodeIfPresent([String].self, forKey: key) { return values.compactMap { Int($0) } }
        return []
    }

    /// `backdrop_path` is usually `[String]`, sometimes a single string.
    func lenientStringArray(_ key: Key) -> [String] {
        if let values = try? decodeIfPresent([String].self, forKey: key) { return values }
        if let value = try? decodeIfPresent(String.self, forKey: key), !value.isEmpty { return [value] }
        return []
    }
}
