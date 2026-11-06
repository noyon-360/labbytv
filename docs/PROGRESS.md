# LABBY TV (tvOS): Progress

Ticked = built, compiles clean in Swift 5 **and** Swift 6 language mode with no warnings, and runs in the Apple TV 4K simulator.
"Not verified" notes list what still needs a real account, real streams or real hardware.

## Phase 0: Project setup (user does the Xcode parts)
- [ ] Deployment target tvOS 17.0, Swift 6, strict concurrency complete. *Still tvOS 27.2 / Swift 5 in the project; the code already builds clean with `SWIFT_VERSION=6.0`.*
- [x] `Config/*.xcconfig` + `.gitignore` + `Secrets.example.xcconfig` (2026-11-06). *Secrets.xcconfig is git-ignored. Not yet attached to the target in Xcode.*
- [x] Folder skeleton from `FOLDER_STRUCTURE.md` (2026-11-06). *`Assets.xcassets` not moved to `Resources/` yet (needs an Xcode check).*
- [ ] `labbytvTests` target (Swift Testing). *Test files are written in `labbytvTests/`; the target doesn't exist yet, so they haven't run.*
- [ ] Info.plist: `NSAppTransportSecurity › NSAllowsArbitraryLoads = YES` (Xtream streams and logos are plain `http://`) and `RevenueCatAPIKey = $(REVENUECAT_API_KEY)`.

## Phase 1: Proof of concept
- [x] `APIClient` + `APIResponse` + `APIError` + token refresh (2026-11-06): `Core/Networking/*`. Shared refresh task, refresh-token rotation, `X-Device-ID`, logout only on explicit rejection.
- [x] `KeychainStore` + `SessionStore` (2026-11-06): `Core/Storage/*`. Tokens + active playlist (holds the IPTV password) in Keychain.
- [x] `AppEnvironment` + `AppRouter` (2026-11-06): `App/*`.
- [x] Login screen with welcome text (2026-11-06): `Features/Auth/Views/LoginView.swift`, `LoginWelcomeIntro.swift` (copy word for word from Flutter). Flutter TV layout: intro on top, QR left with initial focus on "Get a new code", OR, email form right (Forget Password / Login / Sign Up). TV QR sign-in confirmed working with a real account in the simulator. *Not re-screenshotted after the layout change (simulator is signed in).*
- [x] Playlist fetch + picker (+ add playlist) (2026-11-06): `Features/Playlist/*`. *Not verified against real data.*
- [x] Live channels, first page (2026-11-06): `Core/Catalog/*`, `Features/LiveTV/*`.
- [x] Full-screen player (`AVPlayerViewController`) (2026-11-06): `Core/Player/*`.
- [ ] **Stream-format test.** From the backend code (`server.controller.js`): live is always `.m3u8` (HLS, AVPlayer OK); movies use the provider's `container_extension` (fallback `.mkv`); episodes are built client-side with `container_extension` (fallback `.mkv`). AVPlayer cannot play MKV/AVI. The app logs `Stream test: <type> .<ext> → plays/failed` (category `player`) for every stream.
  - 2026-11-06, real account (provider labmax.live): TV QR sign-in, profile, playlists, history and catalog all work. Movie 230169080 (`.mkv`, `http://`) failed with ATS `-1022` before reaching the decoder, so ATS must be allowed first. After that, MKV still needs re-testing (expected to fail in AVPlayer). Live HLS not yet tested.

## Phase 2: Core app
- [x] Design system + shared focusable components (2026-11-06): `Core/DesignSystem/*`, `Core/Components/*`
- [x] Main tabs (sidebar) (2026-11-06): `App/MainTabView.swift`, `.sidebarAdaptable` on tvOS 18+, top tabs on 17
- [x] Home shelves (2026-11-06): `Features/Home/*`
- [x] Live TV: category chips, grid, paging + de-dup, channel up/down (2026-11-06). *Channel up/down: swipe or click up/down on the remote. Not tested on a real Siri Remote.*
- [x] Movies: categories, grid, detail, play, resume (2026-11-06)
- [x] Series: categories, grid, detail, seasons, episodes (2026-11-06)
- [x] Search across all types (2026-11-06)

## Phase 3: Premium & account
- [ ] RevenueCat setup + `PremiumService` + backend verify. *Code done in `Core/Premium/PremiumService.swift` behind `#if canImport(RevenueCat)`; needs the SPM package + API key. Backend "verify" isn't called: Flutter doesn't call it either, and the backend uses the RevenueCat webhook as source of truth.*
- [ ] Paywall + Restore Purchases. *UI done (`Features/Subscription/*`); untestable until RevenueCat is linked.*
- [x] EPG guide grid (premium) with per-channel cache and now-line (2026-11-06): `Features/EPG/*`
- [x] Watch history (continue watching) + favourites (2026-11-06): `Features/WatchHistory/*`
- [x] Profile + legal text + logout (2026-11-06): `Features/Profile/*`
- [x] Sign up, forgot password (OTP), TV QR login (2026-11-06): `Features/Auth/*`

## Phase 4: Release prep
- [ ] Layered app icon + Top Shelf images
- [ ] `PrivacyInfo.xcprivacy`
- [ ] Full Siri-Remote-only pass on every screen, with no dead ends
- [ ] App Store screenshots 1920×1080

## Known gaps / decisions
- Watch history stores only the episode id for series, so "Continue Watching" can resume an episode only if it was last played on this Apple TV (the TV remembers series id and extension locally in `Preferences`). Same limit as the Flutter app.
- The Flutter repos for Live/Movies/Series/Genre/Search are merged into one `CatalogRepository` + generic `CatalogViewModel` (same endpoints and body).
- Out of scope, not built: parental lock, EPG reminders, watch later, downloads, notifications, announcements.
