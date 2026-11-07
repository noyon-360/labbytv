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
- [ ] RevenueCat setup + `PremiumService` + backend verify. *Code done in `Core/Premium/PremiumService.swift` behind `#if canImport(RevenueCat)`. 2026-11-07: `purchases-ios-spm` 5.102.3 linked (RevenueCat product only), RevenueCat code now compiles; `REVENUECAT_API_KEY` set in `Config/Secrets.xcconfig` (same Apple key as the iPhone app: same bundle ID `com.almightyflippa.labbytv`, universal purchase); `RevenueCatAPIKey = $(REVENUECAT_API_KEY)` in `Info.plist`. **Pending:** set `Secrets.xcconfig` as the target's base configuration in Xcode (verified with `-xcconfig` that the key then reaches the built Info.plist), then a sandbox purchase test. Backend "verify" isn't called: Flutter doesn't call it either, and the backend uses the RevenueCat webhook as source of truth.*
- [ ] Paywall + Restore Purchases. *UI done (`Features/Subscription/*`); untestable until RevenueCat is linked.* 7-day free trial copy added 2026-11-07 (same as Flutter): `Core/Premium/FreeTrialOffer.swift`, trial badge + terms in `PlanCard` / `PaywallView`, "You're on your free trial" status from RevenueCat `periodType == .trial` or backend `subscriptionStatus == "trialing"`. Tests in `labbytvTests/Models/FreeTrialOfferTests.swift` (no test target yet). Premium system pass 2026-11-07: backend premium now needs `plan == "premium"` AND a live period (was `|| plan == "premium"`, which kept expired users premium until the daily job); Guide upsell offers "Start 7-Day Free Trial"; Profile shows "LABBY TV Pro · Free trial"; PiP explicitly off in `PlayerSurface` (not built on tvOS; AVPlayerViewController enables it by default).
- [x] EPG guide grid (premium) with per-channel cache and now-line (2026-11-06): `Features/EPG/*`
- [x] Watch history (continue watching) + favourites (2026-11-06): `Features/WatchHistory/*`
- [x] Profile + legal text + logout (2026-11-06): `Features/Profile/*`
- [x] Sign up, forgot password (OTP), TV QR login (2026-11-06): `Features/Auth/*`

- [x] Parental lock (2026-11-07, requested by user; port of Flutter mobile `ParentalLockService`). `Core/ParentalLock/*` (rules, service, prompt), `Features/ParentalLock/*` (PIN pad, settings screen), Profile → Parental Lock (asks PIN first). 4-digit PIN stored as salted SHA-256 in Keychain; locked category ids per type in `Preferences`; both survive sign-out (as Flutter). Locked items hidden from "All" in Live/Guide/Movies/Series, Home and Search; locked chips show a lock and ask for the PIN; 5 wrong tries = 30 s cooldown; "Forgot PIN?" removes the PIN with the account password (`POST /user/verify-password`); every unlock ends when the app goes to background. No biometrics (Apple TV has none). Tests: `labbytvTests/Models/ParentalLockTests.swift` (type-checked, not run: no test target). *Not checked by hand in the simulator or on a Siri Remote.* Same gaps as Flutter: Favorites, Watch History and Continue Watching are not filtered. **Premium gate (2026-11-07):** paid Premium only, not the free trial (same as Flutter). `ParentalLockRules.premiumBlockMessage` + Profile alert with "See Plans"; a parent who already set a PIN keeps access after the plan ends. Tests: `ParentalLockPremiumTests`.

## Phase 4: Release prep
- [x] Layered app icon + Top Shelf images (2026-11-07): `Assets.xcassets/App Icon & Top Shelf Image.brandassets`. Drawn as vectors from the Flutter `splash_and_login_logo.png` shapes by `scripts/generate-brand-assets.swift`: Back = logo yellow `#FBB41E`, Middle = black L, Front = white bolt (parallax). Icon 400×240 @1x/@2x + 1280×768 App Store; Top Shelf 1920×720 and Wide 2320×720 (@1x/@2x) with mark + "LABBY TV". Seen on the simulator home screen. *Parallax feel not checked on a real Siri Remote.*
- [x] `PrivacyInfo.xcprivacy` (2026-11-07): `Resources/PrivacyInfo.xcprivacy`, copied into the app bundle. No tracking. Collected (linked, app functionality only): email, name, user ID, device ID (random `X-Device-ID`), purchase history, other user content (IPTV playlists), other usage data (watch history, favourites). Required-reason API: UserDefaults `CA92.1`. RevenueCat ships its own manifest. *App Store Connect privacy labels must match this list.*
- [ ] Full Siri-Remote-only pass on every screen, with no dead ends
- [ ] App Store screenshots 1920×1080

## Known gaps / decisions
- Watch history stores only the episode id for series, so "Continue Watching" can resume an episode only if it was last played on this Apple TV (the TV remembers series id and extension locally in `Preferences`). Same limit as the Flutter app.
- The Flutter repos for Live/Movies/Series/Genre/Search are merged into one `CatalogRepository` + generic `CatalogViewModel` (same endpoints and body).
- Out of scope, not built: EPG reminders, watch later, downloads, notifications, announcements.

## VLC playback for MKV (added 2026-11-06, approved by user)
- [x] `Packages/LabbyVLC`: local Swift package wrapping official VideoLAN **TVVLCKit 3.7.4** (LGPLv2.1, archive SHA-256 verified). Binary is git-ignored; `scripts/fetch-vlckit.sh` downloads and verifies it. Package builds for tvOS in Swift 6 mode.
- [x] App side: `PlayerViewModel` picks VLC for containers AVPlayer can't open (mkv, avi, …), AVPlayer for m3u8/mp4/mov. `Core/Player/VLCPlayerView.swift`: Siri Remote controls (Play/Pause, ±10 s, Audio, Subtitles, Menu hides then closes). Resume + 10 s progress sync work for both engines. "Open Source Licenses" page in Profile credits VLCKit.
- [x] Player aspect ratio + playback speed (2026-11-06). Aspect: Fit / Zoom / Stretch, saved in `Preferences` (`Core/Player/VideoAspectMode.swift`). AVPlayer: "Aspect Ratio" menu in the transport bar (`transportBarCustomMenuItems`) + the system speed control (`AVPlayerViewController.speeds`, hidden for live). VLC: Speed and Aspect buttons in `VLCPlayerView`. Speeds 0.5×–2× (`Core/Player/PlaybackSpeed.swift`), VOD only. Tests: `labbytvTests/ViewModels/PlayerOptionsTests.swift` (not run, no test target yet). *Not checked on a real Siri Remote or real streams.*
- [x] Package linked in Xcode (2026-11-06). App builds clean in Swift 5 and 6 with VLC compiled in; `TVVLCKit.framework` is embedded.
- [ ] Test an MKV movie in the simulator, then on a real Apple TV (smoothness, 4K, subtitles).
- Note: VLC does its own networking, so ATS doesn't block VLC streams. AVPlayer (live TV) and poster images still need `Allow Arbitrary Loads`.

### Provider findings (2026-11-06, labmax.live account, tested with curl from the dev Mac)
- Account: Active, expires 2027-09-21, 0/5 connections. Allowed outputs: ts, m3u8, rtmp.
- Every stream URL redirects twice (labmax.live → https → a CDN); each attempt took ~70–95 s.
- **Live** (`/live/…m3u8` → prolab.vip): 403 with default/curl user agent, **200 with `Lavf/60.3.100`** (the Android player's UA). Both players now send that UA.
- **Movies** (`/movie/…mkv` → stream.m8tricks.net/vod-api): **403 "This stream URL requires a signed token"** with every UA tried. Provider-side; no client can play it without that token. Need to confirm whether the Android app plays the same movie (227749095 / 230169080).
- **Root cause of slow starts (2026-11-06):** labmax.live resolves to two Cloudflare IPs; `104.21.37.228` is unreachable from the dev network, `172.67.214.171` answers in 0.09 s. VLC tries addresses one by one (~45 s timeout per redirect hop, ~3 min total). Fix: `Core/Player/StreamURLResolver.swift` follows redirects with URLSession (races addresses) and hands VLC the final CDN URL. Measured: 222312851 → 2.3 s (206, MKV); 227749095 → 2.9 s (403, shown as "provider refused").
- Not yet verified: VLC drawing video in the simulator (earlier log showed `h264 get_buffer() failed / no frame!`). May need a real Apple TV.
