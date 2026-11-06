# LABBY TV: Apple TV (tvOS) App

Native SwiftUI Apple TV app for **LABBY TV**, an IPTV player (Live TV with EPG, movies, series) for the client **almightyflippa** (US). The phone and Android TV apps are Flutter, but Flutter can't target tvOS, so this is a separate Swift project. It talks to the **same backend** and must behave the same way.

You work on this project as a **senior tvOS engineer**. Write modern, current Swift and SwiftUI that follows Apple's latest guidance for Apple TV: the focus engine, Siri Remote, the 10-foot UI and AVKit.

---

## "Start coding": what to do

When the user says **"start coding"**, **"start code"**, **"continue"**, **"next"**, **"build the next part"** or something similar:

1. **Read the state.** Open `docs/PROGRESS.md`. If it doesn't exist (first run), create it from the phase checklist under "Phases" below, with every item unchecked.
2. **Pick the next unchecked item** in the current phase, unless the user names a different one. Work on **one item at a time** (one screen, one service or one model group).
3. **Read the reference before writing models or API calls.** Open the matching Flutter files (see "Reference repos") and copy exact field names, request bodies and endpoint paths. **Never guess a field name.**
4. **Write the code** following the structure in `FOLDER_STRUCTURE.md` and the rules below.
5. **Verify it** (see "Build & verify"): it builds with no new warnings, tests pass, and you add a Swift Testing test for any pure logic.
6. **Update `docs/PROGRESS.md`:** tick `[x]` with the date and the key files. Tick only items that are built and verified.
7. **Report back** in short form: what you added, how you verified it, what you could **not** test (real Apple TV, real streams, purchases) and what comes next.
8. **At the end of a phase, stop** and wait for the user to say "start coding" again. Phase 1 especially: report stream-format findings before continuing.

If something blocks you (a missing API key, an unclear backend shape, a stream format AVPlayer can't play), **stop and ask**. Don't invent a workaround or placeholder that looks real.

---

## Key documents

| File | What it is |
|---|---|
| `FOLDER_STRUCTURE.md` | Where every file goes, and the layers and naming. Follow it. |
| `docs/PROGRESS.md` | Phase checklist. The single source of truth for what's done. |
| `/Users/noyon/Documents/Flutter/flutter_allmightyphlippa/docs/tvos_app_prompt.md` | The original build brief: screens, endpoints, phases, rules. |

## Reference repos (read only)

| Repo | Path | Use it for |
|---|---|---|
| Flutter app | `/Users/noyon/Documents/Flutter/flutter_allmightyphlippa` | `lib/core/constants/api_constants.dart` (all endpoints), `lib/features/*/models/` (field names), `lib/features/*/repo*/*_impl.dart` (request bodies), controllers (behaviour such as paging + de-dup, channel switching, EPG caching, premium gating). |
| Backend (Node/Express) | `/Users/noyon/Documents/Backend/backend_almightyflippa` | `mainroute/index.js` + `route/*.route.js` + `controller/*.controller.js` when an API shape is unclear. |

Rules:
- **Never edit, commit or run write commands** in either repo. If a feature needs a backend change, stop and tell the user what, where and why.
- **Never read or print** the backend `.env` or `secret/` folder.
- The Flutter debug logs print passwords and tokens. **Don't copy that.**

---

## Tech stack (modern only)

| Area | Use | Don't use |
|---|---|---|
| Language | **Swift 6**, strict concurrency, `async/await`, `actor`, `Sendable` | Completion handlers, `DispatchQueue` for app logic, Combine pipelines |
| UI | **SwiftUI**, `NavigationStack`, `TabView` (sidebar style on tvOS), `LazyVGrid` / `LazyHStack` / `ScrollView` | Storyboards, UIKit screens (except the player wrapper) |
| State | **`@Observable`** (Observation framework), `@State`, `@Bindable`, `@Environment(Type.self)` | `ObservableObject` / `@Published` / `@StateObject` / `@EnvironmentObject` |
| Focus | `@FocusState`, `.focusable()`, `.focused()`, `.focusSection()`, `.defaultFocus()`, `.prefersDefaultFocus`, `.buttonStyle(.card)` / custom `ButtonStyle` with `isFocused`, `.onMoveCommand`, `.onExitCommand`, `.onPlayPauseCommand` | Custom gesture hacks for navigation |
| Video | **AVKit**: `AVPlayerViewController` wrapped in `UIViewControllerRepresentable`, `AVPlayer`, `AVPlayerItem`, `AVPlayerItemMetadata` for title/artwork in the info panel | `VideoPlayer` (SwiftUI) for full-screen playback, since it lacks tvOS transport bar features |
| Networking | `URLSession` + `async/await` + `Codable` (`JSONDecoder` with explicit `CodingKeys` where names differ) | Alamofire or other networking libs |
| Secure storage | **Keychain** (Security framework) for tokens + IPTV credentials | `UserDefaults` for anything secret |
| Settings | `@AppStorage` / `UserDefaults` for non-secret prefs only | |
| Images | `AsyncImage` + a small `NSCache`/`URLCache`-backed cache | Third-party image libs unless the user approves |
| Purchases | **RevenueCat `purchases-ios`** (SPM) | StoreKit-only custom flows |
| Logging | `os.Logger` with privacy (`\(value, privacy: .private)`) | `print` |
| Tests | **Swift Testing** (`import Testing`, `@Test`, `#expect`) | New XCTest unit tests (XCTest only for UI tests) |

- **Third-party packages:** only RevenueCat, plus a VLC-based player if the user approves it after the Phase 1 stream test. Ask before adding anything else.
- **APIs newer than the deployment target:** wrap them in `if #available(tvOS 18, *)` with a fallback. Example: the `Tab` type in `TabView` is tvOS 18+.

---

## Architecture

```
View  →  ViewModel (@Observable, @MainActor)  →  Repository (protocol)  →  APIClient (actor)  →  backend
```

- **Views** render state and forward actions. No networking, no business logic.
- **ViewModels** are `@MainActor @Observable final class`. They hold screen state (`items`, `isLoading`, `error`, `page`) and expose `async` methods. They don't import SwiftUI.
- **Repositories** are a `protocol` + `…Live` implementation (the Flutter equivalent is abstract repo + `_impl`), so previews and tests can use mocks.
- **APIClient** is an `actor`. It unwraps `{ success | status, message, data }`, adds `Authorization: Bearer`, and on 401 refreshes the token **once** (concurrent 401s share one refresh task), retries, then logs out.
- **Dependency injection:** `AppEnvironment` builds the shared services once in `LabbyTVApp`. Inject them with `.environment(...)`, and pass repositories to view-model initialisers. No singletons except where Apple's or RevenueCat's API requires one.
- **Errors:** one `APIError` enum. Every screen shows a focusable **Retry**, so the user never hits a dead end.

### Backend facts (verify against the Flutter code)
- Base URL `https://api.labbytv.com/api/v1`. Most calls are POST with a JSON body.
- The app never calls the IPTV server directly. It sends the active playlist's `serverUrl / username / password` to the backend, which proxies Xtream.
- `/server/get-play-url` returns `playUrl`, and that's what AVPlayer plays.
- **Xtream catalog order isn't stable across pages,** so de-duplicate by id on load-more.
- **EPG titles and descriptions are base64.** EPG is fetched **one channel at a time** with `from`/`to` in Unix seconds (UTC), so cache per channel and load only the visible rows.
- Premium entitlement: **`LABBY TV Pro`**. Call `Purchases.logIn(userId)` after login. Gate only the features the brief names (EPG guide, no watermark).

---

## tvOS UX rules (must pass for every screen)

- **Siri Remote only:** every screen works with swipe, click, Play/Pause and Back/Menu. No touch-only interaction.
- **Visible focus everywhere:** scale or lift plus shadow on cards, and a highlight on buttons and chips. Use `.buttonStyle(.card)` or the shared styles in `Core/Components`.
- **Sensible initial focus** on every screen (`.defaultFocus` / `.prefersDefaultFocus`). After going back, focus returns to where the user was.
- **Back/Menu always goes back one level.** On the root tab it exits to the Apple TV home screen (system behaviour, so don't block it).
- **Use `.focusSection()`** on rows, shelves and the category chip bar so swiping between them works.
- **10-foot UI:** large type (body ≥ 29 pt, titles bigger), respect the TV safe area (don't use `.ignoresSafeArea` for content), dark theme, 16:9 only.
- **Performance:** lazy stacks and grids, paging (20–50 items), cancel tasks when a view disappears (`.task(id:)`), and downsize poster images.
- **Player:** live channel up/down by swiping up/down while playing (switch within the current category). VOD resumes from the saved position. Subtitle and audio menus come from `AVPlayerViewController`.

---

## Rules

- **Follow `FOLDER_STRUCTURE.md`.** One type per file, and the file name matches the type. Views end in `View`, view models in `ViewModel`, repositories in `Repository`.
- **Xcode project:** the project uses folders that stay in sync with disk, so files you create are compiled automatically. **Don't hand-edit `labbytv.xcodeproj`.** For build-setting or SPM changes (deployment target, Swift version, adding RevenueCat), tell the user the exact steps in Xcode.
- **Secrets:** the RevenueCat key lives in `Config/Secrets.xcconfig`, which is git-ignored and read through `Info.plist`. Never hard-code keys, and never log passwords, tokens or IPTV credentials.
- **Comments explain why** (platform quirks, Xtream oddities, races), not what the code does.
- Use colours and fonts from `Core/DesignSystem`, not hard-coded values. UI text is English and hard-coded for now.
- Every view gets a `#Preview` that uses mock repositories and data from `Preview Content/`.
- **Git:** only commit or push when the user asks. Don't create branches; work on the current one. Never commit `Secrets.xcconfig`.
- **Don't change scope.** Features beyond the brief (Top Shelf extension, multi-user profiles, Siri search) need the user's OK first.

---

## Build & verify

```bash
# Build (simulator)
xcodebuild -project labbytv.xcodeproj -scheme labbytv \
  -destination 'platform=tvOS Simulator,name=Apple TV 4K (4th generation)' build

# Unit tests (once labbytvTests exists)
xcodebuild -project labbytv.xcodeproj -scheme labbytv \
  -destination 'platform=tvOS Simulator,name=Apple TV 4K (4th generation)' test

# List available simulators if the name above doesn't exist
xcrun simctl list devices available | grep -i "apple tv"
```

- After each item: **build succeeds with no new warnings** (Swift 6 concurrency warnings count) and tests pass.
- Unit-test pure logic: response decoding, token refresh, EPG base64 + time maths, paging + de-dup, and view-model state.
- Say plainly what you couldn't test: real Apple TV hardware, real provider streams, sandbox purchases, Siri Remote feel. The user runs those in Xcode.
- The simulator's `XPC error received on message reply handler` log is harmless noise.

---

## Phases

Copy this into `docs/PROGRESS.md` on the first "start coding".

**Phase 0: Project setup** (user does the Xcode parts, guided by you)
- [ ] Deployment target tvOS 17.0, Swift 6, strict concurrency complete
- [ ] `Config/*.xcconfig` + `.gitignore` + `Secrets.example.xcconfig`
- [ ] Folder skeleton from `FOLDER_STRUCTURE.md`, `Assets.xcassets` moved to `Resources/`
- [ ] `labbytvTests` target (Swift Testing)

**Phase 1: Proof of concept (stop and report after this phase)**
- [ ] `APIClient` + `APIResponse` + `APIError` + token refresh
- [ ] `KeychainStore` + `SessionStore`
- [ ] `AppEnvironment` + `AppRouter`
- [ ] Login screen
- [ ] Playlist fetch + picker
- [ ] Live channels, first page
- [ ] Full-screen player (`AVPlayerViewController`)
- [ ] **Stream-format test:** log the `playUrl` formats for live/movie/series and report which play in AVPlayer (HLS/MP4 work, while raw TS/MKV don't). If many fail, give the user options and don't pick one.

**Phase 2: Core app**
- [ ] Design system + shared focusable components
- [ ] Main tabs (sidebar)
- [ ] Home shelves
- [ ] Live TV: category chips, grid, paging + de-dup, channel up/down
- [ ] Movies: categories, grid, detail, play, resume
- [ ] Series: categories, grid, detail, seasons, episodes
- [ ] Search across all types

**Phase 3: Premium & account**
- [ ] RevenueCat setup + `PremiumService` + backend verify
- [ ] Paywall + Restore Purchases
- [ ] EPG guide grid (premium) with per-channel cache and now-line
- [ ] Watch history (continue watching) + favourites
- [ ] Profile + legal text + logout
- [ ] Sign up, forgot password (OTP), TV QR login (matches the Flutter TV login approval)

**Phase 4: Release prep**
- [ ] Layered app icon + Top Shelf images
- [ ] `PrivacyInfo.xcprivacy`
- [ ] Full Siri-Remote-only pass on every screen, with no dead ends
- [ ] App Store screenshots 1920×1080
