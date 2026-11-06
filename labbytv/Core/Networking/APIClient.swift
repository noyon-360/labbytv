import Foundation
import os

/// The only type that talks to the backend.
///
/// Unwraps the `{ success, message, data }` envelope, adds the Bearer token,
/// and on a 401 refreshes the token once (concurrent 401s share one refresh),
/// retries, and ends the session if the refresh token is rejected.
actor APIClient {
    private let baseURL: URL
    private let urlSession: URLSession
    private let store: any SecureStore
    private let onSessionExpired: @Sendable () async -> Void

    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private var refreshTask: Task<RefreshOutcome, Never>?

    init(
        baseURL: URL = APIEndpoint.baseURL,
        urlSession: URLSession = .shared,
        store: any SecureStore,
        onSessionExpired: @escaping @Sendable () async -> Void
    ) {
        self.baseURL = baseURL
        self.urlSession = urlSession
        self.store = store
        self.onSessionExpired = onSessionExpired
    }

    // MARK: Public API

    /// POSTs `body` as JSON and returns the decoded `data` field.
    func post<Body: Encodable & Sendable, Response: Decodable & Sendable>(
        _ endpoint: APIEndpoint,
        body: Body,
        as responseType: Response.Type = Response.self
    ) async throws -> Response {
        let bodyData: Data
        do {
            bodyData = try encoder.encode(body)
        } catch {
            Logger.network.error("Encoding failed for \(endpoint.path, privacy: .public)")
            throw APIError.unknown
        }
        return try await send(endpoint, method: "POST", query: [], body: bodyData, allowRefresh: true)
    }

    func get<Response: Decodable & Sendable>(
        _ endpoint: APIEndpoint,
        query: [URLQueryItem] = [],
        as responseType: Response.Type = Response.self
    ) async throws -> Response {
        try await send(endpoint, method: "GET", query: query, body: nil, allowRefresh: true)
    }

    // MARK: Request pipeline

    private func send<Response: Decodable & Sendable>(
        _ endpoint: APIEndpoint,
        method: String,
        query: [URLQueryItem],
        body: Data?,
        allowRefresh: Bool
    ) async throws -> Response {
        let request = makeRequest(endpoint, method: method, query: query, body: body)
        let (data, status) = try await perform(request)
        Logger.network.debug("\(method, privacy: .public) \(endpoint.path, privacy: .public) → \(status)")

        if status == 401 && endpoint.requiresAuth {
            guard allowRefresh else { throw APIError.unauthorized }
            switch await refreshTokens() {
            case .refreshed:
                return try await send(endpoint, method: method, query: query, body: body, allowRefresh: false)
            case .sessionEnded:
                throw APIError.unauthorized
            case .failed(let error):
                throw error
            }
        }
        return try unwrap(data, status: status)
    }

    private func makeRequest(
        _ endpoint: APIEndpoint,
        method: String,
        query: [URLQueryItem] = [],
        body: Data?,
        extraHeaders: [String: String] = [:]
    ) -> URLRequest {
        var url = baseURL.appending(path: endpoint.path)
        if !query.isEmpty {
            url.append(queryItems: query)
        }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.httpBody = body
        request.timeoutInterval = 60
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if endpoint.requiresAuth, let token = store.string(for: .accessToken) {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        for (field, value) in extraHeaders {
            request.setValue(value, forHTTPHeaderField: field)
        }
        return request
    }

    private func perform(_ request: URLRequest) async throws -> (Data, Int) {
        do {
            let (data, response) = try await urlSession.data(for: request)
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            return (data, status)
        } catch let error as URLError {
            throw Self.map(error)
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            throw APIError.unknown
        }
    }

    private func unwrap<Response: Decodable>(_ data: Data, status: Int) throws -> Response {
        let envelope: APIResponse<Response>
        do {
            envelope = try decoder.decode(APIResponse<Response>.self, from: data)
        } catch {
            if (200..<300).contains(status) {
                Logger.network.error("Decoding failed: \(String(describing: error), privacy: .public)")
                throw APIError.decoding
            }
            // Non-JSON error page (proxy, 502, etc.).
            throw APIError.server(status: status, message: "")
        }

        guard (200..<300).contains(status), envelope.success else {
            throw APIError.server(status: status, message: envelope.errorMessage)
        }
        guard let payload = envelope.data else {
            if let empty = EmptyResponse() as? Response {
                return empty
            }
            Logger.network.error("Response had success=true but no data")
            throw APIError.decoding
        }
        return payload
    }

    nonisolated private static func map(_ error: URLError) -> Error {
        switch error.code {
        case .cancelled:
            return CancellationError()
        case .timedOut:
            return APIError.timeout
        case .notConnectedToInternet, .networkConnectionLost, .cannotFindHost,
             .cannotConnectToHost, .dnsLookupFailed, .dataNotAllowed:
            return APIError.noConnection
        default:
            return APIError.unknown
        }
    }

    // MARK: Token refresh

    private enum RefreshOutcome: Sendable {
        case refreshed
        /// The backend rejected the refresh token; the user was signed out.
        case sessionEnded
        /// Network or server trouble; keep the session and surface the error.
        case failed(APIError)
    }

    private nonisolated struct RefreshRequest: Encodable, Sendable {
        let refreshToken: String
    }

    private nonisolated struct RefreshResponse: Decodable, Sendable {
        let accessToken: String?
        let refreshToken: String?
    }

    /// Every caller that hits a 401 while a refresh is running awaits the same
    /// task. The task is stored before the first suspension point, so actor
    /// re-entrancy can't start a second refresh. Two parallel refreshes would
    /// break: the backend rotates the refresh token, so the loser's is invalid.
    private func refreshTokens() async -> RefreshOutcome {
        if let refreshTask {
            return await refreshTask.value
        }
        let task = Task { await self.performRefresh() }
        refreshTask = task
        let outcome = await task.value
        refreshTask = nil
        return outcome
    }

    private func performRefresh() async -> RefreshOutcome {
        guard let refreshToken = store.string(for: .refreshToken) else {
            await endSession()
            return .sessionEnded
        }

        let body: Data
        do {
            body = try encoder.encode(RefreshRequest(refreshToken: refreshToken))
        } catch {
            return .failed(.unknown)
        }
        // The backend keys sessions per device; the header lets it migrate
        // an older single-token session onto this device.
        let request = makeRequest(
            .refreshToken,
            method: "POST",
            body: body,
            extraHeaders: ["X-Device-ID": store.deviceID()]
        )

        do {
            let (data, status) = try await perform(request)
            Logger.network.debug("POST \(APIEndpoint.refreshToken.path, privacy: .public) → \(status)")
            let tokens: RefreshResponse = try unwrap(data, status: status)
            guard let access = tokens.accessToken, let refresh = tokens.refreshToken else {
                return .failed(.decoding)
            }
            store.set(access, for: .accessToken)
            store.set(refresh, for: .refreshToken)
            return .refreshed
        } catch APIError.server(let status, _) where status == 401 || status == 403 || (200..<300).contains(status) {
            // Explicit rejection (401/403, or 200 with success=false).
            await endSession()
            return .sessionEnded
        } catch let error as APIError {
            // 5xx, timeouts, offline: don't sign the user out over a flaky network.
            return .failed(error)
        } catch {
            return .failed(.unknown)
        }
    }

    private func endSession() async {
        Logger.auth.notice("Refresh token rejected; ending session")
        store.clearSession()
        await onSessionExpired()
    }
}
