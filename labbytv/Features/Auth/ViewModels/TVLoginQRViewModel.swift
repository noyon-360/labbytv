import Foundation
import Observation
import os

/// Sign in by scanning a QR code with the LABBY TV phone app (matches the
/// Flutter `TvQrLoginController`): get a code, poll until the phone approves,
/// and fetch a fresh code whenever one expires or is declined.
@MainActor
@Observable
final class TVLoginQRViewModel {
    enum State: Equatable {
        case loading
        case showing(TVLoginCode)
        case failed(String)
    }

    private(set) var state: State = .loading
    private(set) var notice: String?
    /// Bumped by "Get a new code"; the view's `.task(id:)` restarts `run()`.
    private(set) var attempt = 0

    @ObservationIgnored private let repository: any AuthRepository
    @ObservationIgnored private let session: SessionStore
    @ObservationIgnored private let deviceName: String
    @ObservationIgnored private let onSignedIn: @MainActor () async -> Void

    init(repository: any AuthRepository, session: SessionStore, deviceName: String, onSignedIn: @escaping @MainActor () async -> Void = {}) {
        self.repository = repository
        self.session = session
        self.deviceName = deviceName
        self.onSignedIn = onSignedIn
    }

    /// Runs until signed in or cancelled. The view restarts it (via
    /// `.task(id:)`) when the user asks for a new code.
    func run() async {
        state = .loading
        while !Task.isCancelled {
            let code: TVLoginCode
            do {
                code = try await repository.requestTVLoginCode(deviceName: deviceName)
            } catch is CancellationError {
                return
            } catch {
                state = .failed((error as? APIError)?.userMessage ?? APIError.unknown.userMessage)
                return
            }
            state = .showing(code)

            if await poll(code) { return }
        }
    }

    func requestNewCode() {
        notice = nil
        attempt += 1
    }

    /// Returns true once signed in; false when a new code is needed.
    private func poll(_ code: TVLoginCode) async -> Bool {
        let deadline = Date.now.addingTimeInterval(TimeInterval(code.expiresIn))
        while Date.now < deadline {
            do {
                try await Task.sleep(for: .seconds(code.interval))
                let result = try await repository.pollTVLogin(deviceCode: code.deviceCode)
                switch result.status {
                case .pending:
                    continue
                case .approved:
                    guard let login = result.login else { continue }
                    try session.signIn(with: login)
                    Logger.auth.info("Signed in with TV code")
                    await onSignedIn()
                    return true
                case .denied:
                    notice = "The request was declined on the phone. Here is a new code."
                    return false
                case .expired:
                    notice = nil
                    return false
                }
            } catch is CancellationError {
                return true
            } catch APIError.server(let status, _) where status == 404 {
                // Code unknown or already used: start over with a new one.
                return false
            } catch {
                // Flaky network: keep polling the same code.
                continue
            }
        }
        return false
    }
}
