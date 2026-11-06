import Foundation
import os

/// Follows a provider's redirect chain with URLSession before VLC sees the URL.
///
/// Xtream panels answer `/movie/…` with two redirects before the real file.
/// VLC connects to a host's addresses one at a time, so when one of the
/// panel's Cloudflare IPs is unreachable from the viewer's network it waits
/// ~45 s per hop. URLSession races the addresses and moves on quickly. It
/// also lets us read the provider's real answer (e.g. a 403) instead of
/// VLC's endless buffering.
nonisolated enum StreamURLResolver {
    enum Failure: Error, Equatable {
        /// The provider refused this stream (401/403), e.g. "requires a signed token".
        case refused(status: Int)
        case notFound
        case unreachable
    }

    static func resolve(_ url: URL, userAgent: String, timeout: TimeInterval = 40) async throws -> URL {
        var request = URLRequest(url: url, timeoutInterval: timeout)
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        // One byte is enough to make the server commit to an answer.
        request.setValue("bytes=0-0", forHTTPHeaderField: "Range")

        let session = URLSession(configuration: .ephemeral)
        defer { session.finishTasksAndInvalidate() }

        let response: URLResponse
        do {
            (_, response) = try await session.data(for: request)
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            Logger.player.error("Redirect check failed: \(error.localizedDescription, privacy: .public)")
            throw Failure.unreachable
        }

        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        let finalURL = response.url ?? url
        // Host only: the path carries the IPTV username and password.
        Logger.player.notice("Stream resolved to \(finalURL.host() ?? "?", privacy: .public) (HTTP \(status))")
        switch status {
        case 200..<300: return finalURL
        case 401, 403: throw Failure.refused(status: status)
        case 404, 410: throw Failure.notFound
        default: throw Failure.unreachable
        }
    }
}
