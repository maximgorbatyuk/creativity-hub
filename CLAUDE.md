# CreativityHub - CLAUDE.md

## App Identity

The app is named **CreativityHub** (one word, capital C and H). All identifiers use `creativityhub` (lowercase, no separators).

**NEVER use `creativehub`** — always `creativityhub`.

## App Group Identifiers

| Environment | App Group |
|-------------|-----------|
| Release | `group.dev.mgorbatyuk.creativityhub` |
| Debug | `group.dev.mgorbatyuk.creativityhub.dev` |

## Bundle Identifiers

| Target | Environment | Bundle ID |
|--------|-------------|-----------|
| Main app | Release | `dev.mgorbatyuk.CreativityHub` |
| Main app | Debug | `dev.mgorbatyuk.CreativityHub.dev` |
| ShareExtension | Release | `dev.mgorbatyuk.CreativityHub.ShareExtension` |
| ShareExtension | Debug | `dev.mgorbatyuk.CreativityHub.dev.ShareExtension` |

## Build Commands

```bash
cd CreativityHub

# Debug build
xcodebuild -project CreativityHub.xcodeproj -scheme CreativityHub \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' build

# Release build
xcodebuild -project CreativityHub.xcodeproj -scheme CreativityHub \
  -configuration Release \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' build
```

## Project Structure

```
CreativityHub/
├── CreativityHub/          # Main app target
│   ├── Config/             # xcconfig files (Base, Debug, Release)
│   ├── Features/           # Feature views (Today, Projects, Search)
│   ├── Onboarding/         # Onboarding flow
│   ├── Services/           # AnalyticsService
│   ├── Shared/             # Reusable UI components
│   ├── UserSettings/       # Settings view and view model
│   ├── ContentView.swift   # Root view (onboarding → main flow)
│   ├── CreativityHubApp.swift
│   └── Info.plist
├── BusinessLogic/          # Shared between main app and ShareExtension
│   ├── Database/           # DatabaseManager, repositories, migrations
│   ├── Errors/             # AppError, RuntimeError
│   ├── Helpers/            # L(), AppGroupContainer, AppLogger, AppNotifications
│   ├── Models/             # Domain models (Project, Idea, Note, etc.)
│   └── Services/           # LocalizationManager
├── ShareExtension/         # Share Extension target
│   ├── ShareViewController.swift
│   ├── Info.plist
│   ├── ShareExtension.entitlements        # Release
│   └── ShareExtensionDebug.entitlements   # Debug
└── CreativityHub.xcodeproj
```

## Config Files (xcconfig)

Variables defined in xcconfig files and used via `$(VARIABLE_NAME)` in Info.plist and build settings:

- `APP_GROUP_IDENTIFIER` — App Group for shared container between app and ShareExtension
- `SHARE_EXTENSION_BUNDLE_ID` — Bundle ID for the ShareExtension target
- `BUILD_ENVIRONMENT` — `dev` or `release`
- `DEVELOPER_NAME`, `DEVELOPER_TELEGRAM_LINK`, `GITHUB_REPO_URL`, `APP_STORE_ID`

## Entitlements

Each target has separate Debug/Release entitlements:
- Main app: `CreativityHub.entitlements` (Release), `CreativityHubDebug.entitlements` (Debug)
- ShareExtension: `ShareExtension.entitlements` (Release), `ShareExtensionDebug.entitlements` (Debug)

Entitlements must use the exact app group identifiers listed above.

## Localization

Languages: English (`en`), Russian (`ru`), Kazakh (`kk`)

All user-facing strings use the global `L()` function which reads from `*.lproj/Localizable.strings` bundles via `LocalizationManager`.

## Scripts

```bash
# Development setup (installs SwiftLint, SwiftFormat, xcbeautify, creates .env)
./scripts/setup.sh

# Code quality
./scripts/run_format.sh           # Format code with SwiftFormat
./scripts/run_lint.sh             # Lint code with SwiftLint (strict mode)
./scripts/run_all_checks.sh       # Run format + lint + tests
./scripts/detect_unused_code.sh   # Detect unused code with Periphery

# Testing
./run_tests.sh                    # Run tests on iPhone 17 Pro Max simulator with coverage

# Firebase & CI/CD
./scripts/generate_firebase_plist.sh   # Generate GoogleService-Info.plist from scripts/.env
./scripts/build_and_distribute.sh      # Build locally + push to trigger Xcode Cloud
```

Xcode Cloud runs `ci_scripts/ci_post_clone.sh` automatically to generate `GoogleService-Info.plist` from secrets (`FIREBASE_API_KEY`, `FIREBASE_GCM_SENDER_ID`, `FIREBASE_APP_ID`).

## Key Patterns

- **MVVM**: ViewModels use `@Observable`; `LocalizationManager` uses `ObservableObject` (required by `@EnvironmentObject`)
- **Database**: SQLite.swift via App Group shared container. UUIDs stored as String, Decimal stored as String.
- **File system sync**: Xcode auto-compiles source files from `CreativityHub/`, `BusinessLogic/`, and `ShareExtension/` folders — no manual pbxproj edits for source files
- **Analytics**: Firebase Analytics in Release builds only (`#if DEBUG` guard)
- **Color scheme**: Communicated via `NotificationCenter` with `.appColorSchemeDidChange`
