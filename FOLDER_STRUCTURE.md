# LABBY TV (tvOS): Folder Structure

The native Apple TV app for LABBY TV. It uses the same backend as the Flutter phone and Android TV app (`https://api.labbytv.com/api/v1`), so the Swift code is a UI layer plus an API client. The backend proxies Xtream, the same way it does for the Flutter app.

The layout follows the Flutter app: one folder per feature, a shared `Core/`, and the same naming (repository + view model + views + models). That way you can open a Flutter feature and its Swift version side by side.

> Build brief: `flutter_allmightyphlippa/docs/tvos_app_prompt.md`
> Reference code for field names: `flutter_allmightyphlippa/lib/core/constants/api_constants.dart`, `lib/features/*/models/`, `lib/features/*/repo*/`

---

## Full tree

```
labbytv/                              ← repo root
├── labbytv.xcodeproj
├── FOLDER_STRUCTURE.md               ← this file
├── README.md
├── .gitignore                        ← must ignore Config/Secrets.xcconfig
│
├── Config/
│   ├── Base.xcconfig                 ← shared build settings (API base URL)
│   ├── Debug.xcconfig
│   ├── Release.xcconfig
│   ├── Secrets.xcconfig              ← RevenueCat key — git-ignored, never committed
│   └── Secrets.example.xcconfig      ← committed template with empty values
│
├── labbytv/                          ← app target sources
│   │
│   ├── App/
│   │   ├── LabbyTVApp.swift          ← @main entry, sets up AppEnvironment
│   │   ├── AppEnvironment.swift      ← builds & holds shared services (DI container)
│   │   ├── AppRouter.swift           ← decides: Login (with welcome text) → Playlist picker → Main tabs
│   │   └── MainTabView.swift         ← sidebar/top tabs: Home, Live, Guide, Movies, Series, Search, Profile
│   │
│   ├── Core/
│   │   ├── Networking/
│   │   │   ├── APIClient.swift       ← URLSession + async/await, adds Bearer token
│   │   │   ├── APIEndpoint.swift     ← every endpoint path (like api_constants.dart)
│   │   │   ├── APIResponse.swift     ← { success/status, message, data } wrapper
│   │   │   ├── APIError.swift        ← network / decoding / server / unauthorized
│   │   │   └── TokenRefresher.swift  ← 401 → refresh once → retry, else log out
│   │   │
│   │   ├── Storage/
│   │   │   ├── KeychainStore.swift   ← tokens + IPTV credentials (never UserDefaults)
│   │   │   ├── SessionStore.swift    ← logged-in user, active playlist (observable)
│   │   │   └── Preferences.swift     ← non-secret settings (last tab, last category)
│   │   │
│   │   ├── Player/
│   │   │   ├── PlayerView.swift      ← wraps AVPlayerViewController for SwiftUI
│   │   │   ├── PlayerViewModel.swift ← load playUrl, resume position, errors
│   │   │   └── ChannelSwitcher.swift ← swipe up/down = next/prev channel in category
│   │   │
│   │   ├── Premium/
│   │   │   ├── PremiumService.swift  ← RevenueCat, "LABBY TV Pro" entitlement, isPremium
│   │   │   └── PurchaseVerifier.swift← calls /payment/verify-apple-purchase
│   │   │
│   │   ├── Models/                   ← models used by more than one feature
│   │   │   ├── ServerCredentials.swift  ← serverUrl / username / password (ServerRequestModel)
│   │   │   ├── ContentType.swift        ← channels / movies / series
│   │   │   └── PagedResponse.swift
│   │   │
│   │   ├── DesignSystem/
│   │   │   ├── AppColors.swift       ← same palette as Flutter AppColors
│   │   │   ├── AppFonts.swift        ← TV sizes (readable from 3 m)
│   │   │   └── Spacing.swift
│   │   │
│   │   ├── Components/               ← shared focusable UI (like Flutter core/common)
│   │   │   ├── PosterCard.swift      ← focus lift + shadow
│   │   │   ├── ChannelCard.swift
│   │   │   ├── Shelf.swift           ← horizontal row with title
│   │   │   ├── CategoryChips.swift
│   │   │   ├── LoadingView.swift
│   │   │   ├── ErrorView.swift       ← message + Retry button (focusable)
│   │   │   └── EmptyStateView.swift
│   │   │
│   │   └── Utilities/
│   │       ├── Base64.swift          ← Xtream EPG titles/descriptions are base64
│   │       ├── DateFormatting.swift  ← EPG uses Unix seconds (UTC)
│   │       ├── ImageCache.swift      ← posters / channel logos
│   │       └── Logger.swift          ← os.Logger, never logs passwords or tokens
│   │
│   ├── Features/
│   │   ├── Auth/
│   │   │   ├── Models/        LoginRequest.swift, LoginResponse.swift, RegisterRequest.swift
│   │   │   ├── Repository/    AuthRepository.swift
│   │   │   ├── ViewModels/    LoginViewModel.swift, RegisterViewModel.swift, ForgotPasswordViewModel.swift
│   │   │   └── Views/         LoginView.swift, LoginWelcomeIntro.swift, RegisterView.swift, ForgotPasswordView.swift, TVLoginQRView.swift
│   │   │
│   │   ├── Playlist/
│   │   │   ├── Models/        Playlist.swift
│   │   │   ├── Repository/    PlaylistRepository.swift
│   │   │   ├── ViewModels/    PlaylistPickerViewModel.swift
│   │   │   └── Views/         PlaylistPickerView.swift
│   │   │
│   │   ├── Home/
│   │   │   ├── ViewModels/    HomeViewModel.swift
│   │   │   └── Views/         HomeView.swift            ← Continue Watching, Popular Movies/Series shelves
│   │   │
│   │   ├── LiveTV/
│   │   │   ├── Models/        Channel.swift, Category.swift
│   │   │   ├── Repository/    LiveTVRepository.swift
│   │   │   ├── ViewModels/    LiveTVViewModel.swift      ← paging + de-duplicate (Xtream order isn't stable)
│   │   │   └── Views/         LiveTVView.swift, ChannelGridView.swift
│   │   │
│   │   ├── EPG/
│   │   │   ├── Models/        EPGProgram.swift
│   │   │   ├── Repository/    EPGRepository.swift
│   │   │   ├── Services/      EPGCache.swift             ← EPG is one channel per call, so cache it
│   │   │   ├── ViewModels/    GuideViewModel.swift
│   │   │   └── Views/         GuideView.swift, GuideRowView.swift, NowLineView.swift
│   │   │
│   │   ├── Movies/
│   │   │   ├── Models/        Movie.swift, MovieInfo.swift
│   │   │   ├── Repository/    MoviesRepository.swift
│   │   │   ├── ViewModels/    MoviesViewModel.swift, MovieDetailViewModel.swift
│   │   │   └── Views/         MoviesView.swift, MovieDetailView.swift
│   │   │
│   │   ├── Series/
│   │   │   ├── Models/        Series.swift, Season.swift, Episode.swift
│   │   │   ├── Repository/    SeriesRepository.swift
│   │   │   ├── ViewModels/    SeriesViewModel.swift, SeriesDetailViewModel.swift
│   │   │   └── Views/         SeriesView.swift, SeriesDetailView.swift, EpisodeRow.swift
│   │   │
│   │   ├── Search/
│   │   │   ├── ViewModels/    SearchViewModel.swift      ← debounced, searches all 3 types
│   │   │   └── Views/         SearchView.swift
│   │   │
│   │   ├── WatchHistory/
│   │   │   ├── Models/        WatchHistoryItem.swift
│   │   │   ├── Repository/    WatchHistoryRepository.swift
│   │   │   └── ViewModels/    FavoritesViewModel.swift
│   │   │
│   │   ├── Subscription/
│   │   │   ├── ViewModels/    PaywallViewModel.swift
│   │   │   └── Views/         PaywallView.swift, PlanCard.swift
│   │   │
│   │   └── Profile/
│   │       ├── ViewModels/    ProfileViewModel.swift
│   │       └── Views/         ProfileView.swift, LegalTextView.swift
│   │
│   ├── Resources/
│   │   ├── Assets.xcassets           ← app icon (layered), Top Shelf, colours, images
│   │   ├── Localizable.xcstrings     ← optional; UI text is English-only for now
│   │   └── PrivacyInfo.xcprivacy     ← required for App Store (Phase 4)
│   │
│   └── Preview Content/
│       └── MockData.swift            ← sample channels/movies for SwiftUI previews
│
├── labbytvTests/                     ← unit tests (no UI)
│   ├── Networking/  APIResponseDecodingTests.swift, TokenRefresherTests.swift
│   ├── Models/      ChannelDecodingTests.swift, EPGProgramTests.swift (base64 + time)
│   └── ViewModels/  LiveTVViewModelTests.swift (paging + de-dup)
│
└── labbytvUITests/                   ← optional: Siri Remote navigation smoke tests
```

---

## What each layer is for

### `Config/`
Build settings live outside Swift code. `Secrets.xcconfig` holds the **RevenueCat Apple API key** and is git-ignored. Commit `Secrets.example.xcconfig` with empty values so another developer knows what to fill in. Values reach Swift through `Info.plist` (`$(REVENUECAT_API_KEY)`) and are read with `Bundle.main.object(forInfoDictionaryKey:)`.

### `App/`
Startup and navigation only, no business logic.
- `AppEnvironment` creates `APIClient`, `KeychainStore`, `SessionStore`, `PremiumService` once and passes them down with `.environment(...)`. Flutter equivalent: `core/di/`.
- `AppRouter` watches `SessionStore`: no token → Login (welcome text on top, QR + email sign-in, Sign Up link), no active playlist → Playlist picker, otherwise → `MainTabView`.

### `Core/`
Code that every feature uses.

| Folder | Role | Flutter equivalent |
|---|---|---|
| `Networking/` | One `APIClient`. Unwraps `{ success, message, data }` (watch history uses `status`), adds the Bearer token, refreshes once on 401. | `core/api/`, `ApiClient`, `NetworkResult` |
| `Storage/` | Keychain for tokens and the playlist's `serverUrl/username/password`. `SessionStore` is the observable "who is logged in and which playlist is active". | `flutter_secure_storage`, `AuthStorageService` |
| `Player/` | Full-screen `AVPlayerViewController`. It gives Siri Remote scrubbing and subtitle/audio menus for free. Channel up/down lives here so live TV and the EPG guide can both use it. | `LiveVideoPlayScreen`, `VideoPlayScreen` |
| `Premium/` | RevenueCat `Purchases.logIn(userId)` after login, then exposes `isPremium` for the `LABBY TV Pro` entitlement. | `PremiumService`, `revenuecat_service.dart` |
| `Models/` | Only models shared across features. Feature-specific models stay in their feature. | `core/common` base models |
| `DesignSystem/` | Colours and font sizes. Use these instead of hard-coded values. | `AppColors`, `app_theme.dart` |
| `Components/` | Reusable **focusable** views. On tvOS every interactive item needs a visible focus state, so it's built once here. | `TvFocusWrapper`, TV focus widgets |
| `Utilities/` | Base64 decoding for EPG, Unix-time helpers, image cache, a logger that never prints secrets. | `EpgProgramModel` helpers, `DPrint` |

### `Features/<Name>/`
Each feature has the same four sub-folders, so the app stays predictable:

| Sub-folder | Contains | Rule |
|---|---|---|
| `Models/` | `Codable` structs | Copy field names from the Flutter `models/`. Don't guess. |
| `Repository/` | API calls for this feature | Only place that talks to `APIClient`. Returns models or throws. |
| `ViewModels/` | `@Observable` classes with screen state (loading, items, error, page) | No SwiftUI imports. Unit-testable. |
| `Views/` | SwiftUI views | Read the view model, send user actions to it, no networking. |

Small features skip folders they don't need (for example `Home` has no repository because it reuses Movies/Series/WatchHistory).

Data flow is always one way:
```
View  →  ViewModel  →  Repository  →  APIClient  →  backend
View  ←  ViewModel  ←  (models)
```

### `Resources/`
Assets, the privacy manifest and strings. Move `Assets.xcassets` here from the root of `labbytv/`. tvOS app icons are layered (Back / Middle / Front) for the parallax effect, and the Top Shelf images live next to them.

### Tests
Test what is pure logic: response decoding, token refresh, EPG base64 + time math, paging + de-duplication. Views and AVPlayer are checked manually in the Apple TV simulator.

---

## Which folders each phase needs

| Phase | Create these |
|---|---|
| **1: Proof of concept** | `Config/`, `App/`, `Core/Networking`, `Core/Storage`, `Core/Player`, `Core/Components` (basic), `Features/Auth` (login only), `Features/Playlist`, `Features/LiveTV` |
| **2: Core app** | `Features/Home`, `Features/Movies`, `Features/Series`, `Features/Search`, `Core/DesignSystem`, `Core/Utilities/ImageCache` |
| **3: Premium & account** | `Features/EPG`, `Features/Subscription`, `Core/Premium`, `Features/WatchHistory`, `Features/Profile`, rest of `Features/Auth` |
| **4: Release prep** | `Resources/PrivacyInfo.xcprivacy`, icon and Top Shelf assets, `labbytvUITests/` |

You don't need the whole tree on day one. Add folders as each phase starts.

---

## Settings to fix before Phase 1

Found in the current Xcode project:

| Setting | Now | Should be | Why |
|---|---|---|---|
| `TVOS_DEPLOYMENT_TARGET` | 27.2 | 17.0 | 27.2 only runs on the newest Apple TV software. 17.0 covers far more users and still has `@Observable` and the modern focus APIs. |
| `SWIFT_VERSION` | 5.0 | 6.0 (or 5 with strict concurrency) | The brief targets Swift 6. Switching later means fixing many concurrency warnings at once. |
| `PRODUCT_BUNDLE_IDENTIFIER` | `com.almightyflippa.labbytv` | Confirm it matches the iPhone app | Universal Purchase only works if both apps use the same App Store record. Check the iOS bundle ID in the Flutter project's `ios/Runner.xcodeproj` before shipping. |

---

## How to create the folders in Xcode

Newer Xcode projects use **folder references that stay in sync with disk**. Create folders in Finder or Xcode (right-click → New Folder) and the files inside are compiled automatically. If a folder shows up grey or its files aren't compiled, add it with **right-click → Add Files to "labbytv"…** and tick the `labbytv` target.

Naming rules:
- One type per file, file name = type name (`LiveTVViewModel.swift` → `final class LiveTVViewModel`).
- Views end in `View`, view models in `ViewModel`, repositories in `Repository`.
- Repositories are protocols + a live implementation (`protocol LiveTVRepository` / `struct LiveTVRepositoryLive`), the same as the Flutter abstract repo + `_impl`. That way tests and previews can use a mock.
