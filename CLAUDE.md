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
├── CreativityHub/              # Main app target
│   ├── Config/                 # xcconfig files (Base, Debug, Release)
│   ├── Developer/              # Developer-mode-only tools (file browser, settings table, launch screen preview)
│   ├── Features/               # Feature modules (see Features section below)
│   ├── Onboarding/             # Onboarding flow (language selection, intro pages)
│   ├── Services/               # AnalyticsService, BackupService, BackgroundTaskManager, ActivityLogCleanupTaskManager, AppVersionChecker, DeveloperModeManager, RandomDataGenerator
│   ├── Shared/                 # Reusable UI components (EmptyState, ErrorState, Loading, CardBackground, FilterChip, etc.)
│   ├── UserSettings/           # Settings view, view model, iCloud backup list
│   ├── ContentView.swift       # Root view (LaunchScreen → Onboarding → MainTabView)
│   ├── MainTabView.swift       # Bottom tab bar (Today, Active Project, Projects, Settings)
│   ├── CreativityHubApp.swift  # App entry point with AppDelegate, Firebase config
│   └── Info.plist
├── BusinessLogic/              # Shared between main app and ShareExtension
│   ├── Database/               # DatabaseManager, migrations, repositories
│   ├── Errors/                 # AppError, RuntimeError
│   ├── Helpers/                # L(), AppGroupContainer, AppLogger, AppNotifications
│   ├── Models/                 # Domain models (Project, Idea, Note, Checklist, Expense, Document, Reminder, Tag, etc.)
│   └── Services/               # LocalizationManager, DocumentService, ActivityLogService, ActivityAnalyticsService, EnvironmentService
├── CreativityHubTests/         # Unit tests
│   ├── Utils/                  # TestDatabaseHelper, TestHelpers
│   ├── ProjectRepositoryTests.swift
│   ├── NoteRepositoryTests.swift
│   ├── ReminderRepositoryTests.swift
│   ├── DeveloperModeManagerTests.swift
│   ├── ExportModelsTests.swift
│   └── ActivityLogRepositoryTests.swift
├── ShareExtension/             # Share Extension target
│   ├── ShareViewController.swift
│   ├── ShareFormView.swift
│   ├── ShareFormViewModel.swift
│   ├── Models/                 # ShareObjectType, SharedInput
│   ├── Services/               # InputParser
│   ├── Info.plist
│   ├── ShareExtension.entitlements        # Release
│   └── ShareExtensionDebug.entitlements   # Debug
├── scripts/                    # Development & build scripts
├── ci_scripts/                 # Xcode Cloud CI hooks
├── docs/                       # Documentation
└── CreativityHub.xcodeproj
```

## Features

The app has a 4-tab layout (`MainTabView`): Today, Active Project, Projects, Settings.

| Feature | Files | Description |
|---------|-------|-------------|
| **Today** | `TodayView`, `TodayViewModel` | Dashboard with upcoming reminders, quick stats, recent projects, ideas by source |
| **Projects** | 10 files | List/filter by status (active/completed/archived), detail view, content dashboard, create/edit form |
| **Ideas** | 7 files | List (grid/list toggle), detail with source auto-detection (Instagram, TikTok, Pinterest, YouTube, Website), create/edit |
| **Notes** | 5 files | List, detail, create/edit |
| **Checklists** | 8 files | List with progress tracking, detail with item management, create/edit checklist and items |
| **Expenses** | 6 files | List with filtering/sorting, detail, create/edit, expense category management |
| **Tags** | 4 files | Global tag management (list, add/edit form, row component) accessible from User Settings |
| **Documents** | 5 files | List with type detection (PDF, JPEG, PNG, HEIC), document picker, in-app preview |
| **Reminders** | 7 files | List by status, detail, create/edit, upcoming reminders widget |
| **Work Logs** | 5 files | List, create/edit, checklist-item linkage, duration summaries |
| **Search** | `SearchView`, `SearchViewModel` | Global full-text search across all entity types |
| **Activity Analytics** | Integrated in `TodayView` + `ProjectDetailView` | Weekly charts (last 6 months) sourced from activity logs |

## Database

### Repositories (`BusinessLogic/Database/Repositories/`)

| Repository | Purpose |
|------------|---------|
| `ProjectRepository` | CRUD for projects with cascade delete |
| `IdeaRepository` | CRUD for ideas with project filtering |
| `NoteRepository` | CRUD for notes |
| `ChecklistRepository` | CRUD for checklists |
| `ChecklistItemRepository` | CRUD for checklist items |
| `ExpenseRepository` | CRUD for expenses with filtering |
| `ExpenseCategoryRepository` | CRUD for expense categories |
| `TagRepository` | CRUD for tags |
| `ReminderRepository` | CRUD for reminders with project filtering |
| `DocumentRepository` | CRUD for documents with file path management |
| `WorkLogRepository` | CRUD for work logs, project totals, checklist-item detaching |
| `ActivityLogRepository` | Insert/fetch activity logs, daily aggregations, retention cleanup |
| `UserSettingsRepository` | User prefs (language, color scheme, user ID, cleanup metadata) |

### Migrations (`BusinessLogic/Database/Migrations/`)

1. `Migration_20260217_InitialSchema` — Core tables: projects, ideas, notes, checklists, checklist_items, tags, expenses, expense_categories
2. `Migration_20260218_AddDocumentsTable` — Documents table with type & file path
3. `Migration_20260218_AddRemindersTable` — Reminders table with date & status
4. `Migration_20260220_DocumentFilePath` — Document file path refinements
5. `Migration_20260220_AddWorkLogsTable` — Work logs table with checklist item linkage and duration fields
6. `Migration_20260221_AddActivityLogsTable` — Activity logs table for per-project action tracking + analytics source

### Models (`BusinessLogic/Models/`)

`Project`, `Idea`, `Note`, `Checklist`, `ChecklistItem`, `Expense`, `ExpenseCategory`, `Document`, `Reminder`, `WorkLog`, `ActivityLog`, `Tag`, `Currency`, `UserSettings`, `ExportModels`

## Services

### Main App (`CreativityHub/Services/`)

| Service | Purpose |
|---------|---------|
| `AnalyticsService` | Firebase Analytics (Release only). Persistent `user_id` via `UserSettingsRepository.fetchOrGenerateUserId()`, session ID, global properties on every event. |
| `AppVersionChecker` | Compares installed app version with App Store version using `APP_STORE_ID`. Returns `true` when update is available. |
| `BackupService` | iCloud & safety backup orchestration using JSON export payloads. Safety backups in `Documents/creativityhub/safety_backups/` (max 3), iCloud backups (max 5). |
| `BackgroundTaskManager` | Automatic daily backup scheduling via BGTaskScheduler. State in UserDefaults. |
| `ActivityLogCleanupTaskManager` | Daily cleanup task for removing activity logs older than 6 months; stores last run date and deleted count in `user_settings`. |
| `DeveloperModeManager` | 15-tap unlock on app version row. In-memory state only. |
| `RandomDataGenerator` | Test data generation for development |

### Shared (`BusinessLogic/Services/`)

| Service | Purpose |
|---------|---------|
| `EnvironmentService` | Centralized access to Info.plist/build-time environment values (App Store ID/link, version, build environment, developer metadata, app group, bundle id). |
| `LocalizationManager` | `ObservableObject` managing language selection and string lookups (en, ru, kk) |
| `DocumentService` | File operations for documents (save, load, delete) |
| `ActivityLogService` | Centralized write API for project activity events from ViewModels and Share Extension saves |
| `ActivityAnalyticsService` | Aggregates activity logs into daily/weekly chart points (used in Home and Project Detail) |

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

iCloud containers: `iCloud.dev.mgorbatyuk.CreativityHub` (Release), `iCloud.dev.mgorbatyuk.CreativityHub.dev` (Debug). iCloud services use `CloudDocuments` (not `CloudKit`).

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
- **Analytics**: Firebase Analytics in Release builds only (`#if DEBUG` guard). A persistent `user_id` (UUID) is generated on first launch via `UserSettingsRepository.fetchOrGenerateUserId()`, stored in SQLite, and included in every event through `AnalyticsService.getGlobalProperties()`.
- **Color scheme**: `AppColorScheme` enum (system/light/dark) persisted in SQLite via `UserSettingsRepository`, communicated via `NotificationCenter` with `.appColorSchemeDidChange`
- **Activity logs**: User actions are logged through `ActivityLogService` into `activity_logs`; analytics charts read weekly aggregates from `ActivityAnalyticsService`.
- **Activity log retention**: `ActivityLogCleanupTaskManager` runs once per day, deletes logs older than 6 months, and upserts cleanup metadata in `user_settings` (`activity_log_cleanup_last_run_at`, `activity_log_cleanup_last_removed_count`).
- **Backup scope**: Activity logs are intentionally excluded from export/import/iCloud backup payloads.

## App Update Check Pattern

CreativityHub follows Journey Wallet's settings update prompt approach:

- Use `AppVersionChecker` (`CreativityHub/Services/AppVersionChecker.swift`) to call App Store lookup API (`https://itunes.apple.com/lookup?id=<APP_STORE_ID>`) and compare installed version with App Store version.
- Trigger the check from `MainTabView` on appear via `MainTabViewModel`, and pass the result into `UserSettingsView(showAppUpdateButton:)`.
- In `UserSettingsView`, show a highlighted "Update is available" row when the flag is `true`.
- Update action opens App Store link from `EnvironmentService.getAppStoreAppLink()` and tracks analytics event `app_update_button_clicked`.
- Keep all App Store metadata (`APP_STORE_ID`) in xcconfig + Info.plist (never hardcode in code).

## Restart Onboarding Pattern

CreativityHub follows Journey Wallet and EV Charging Tracker's approach for relaunching onboarding from settings:

- Add a dedicated action in `UserSettingsView` About section (same support area as app info/rating).
- On tap, clear onboarding completion flag with `UserDefaults.standard.removeObject(forKey: OnboardingViewModel.onboardingCompletedKey)`.
- Track analytics event `start_onboarding_again_button_clicked` with `screen` and `button_name` properties.
- Use a localized label key for this action (`settings.start_onboarding_again`) in all supported languages.
- Do not add custom navigation logic: root `ContentView` already reacts to the onboarding completion flag and presents onboarding when it is not set.

## Onboarding Background Visual Pattern

CreativityHub follows Journey Wallet and EV Charging Tracker's onboarding visual style with per-screen tinted backgrounds:

- Build onboarding screen with a `ZStack` and render a full-screen gradient background (`.ignoresSafeArea()`) behind page content.
- Language selection page uses a blue/cyan gradient (`Color.blue.opacity(0.3)` to `Color.cyan.opacity(0.1)`).
- Feature pages use each page's own accent color from `OnboardingPageItem.color` with the same opacity pattern (`0.3` and `0.1`).
- Keep gradient selection page-aware in `OnboardingView` (switch by `currentPage`; page index is `currentPage - 1` for feature pages).
- This keeps visual parity across all apps in the workspace and gives each onboarding page a distinct atmosphere.

## Automatic Backup Pattern

CreativityHub follows Journey Wallet's automatic iCloud backup approach:

- Use `BackgroundTaskManager` (`CreativityHub/Services/BackgroundTaskManager.swift`) as the single owner of scheduling and retry logic.
- Persist automatic backup toggle and last successful automatic backup date in `UserDefaults` (inside `BackgroundTaskManager`), not in SQLite.
- Register background tasks in `AppDelegate.application(_:didFinishLaunchingWithOptions:)`, then call `scheduleNextBackup()` at startup.
- Retry pending failed backups in `AppDelegate.applicationWillEnterForeground(_:)` via `BackgroundTaskManager.shared.retryIfNeeded()`.
- Run backups silently through `BackupService.createiCloudBackup()` (no success alerts for automatic runs).
- Keep task identifier synchronized with Info.plist:
  - `BackgroundTaskManager.dailyBackupTaskIdentifier`
  - `BGTaskSchedulerPermittedIdentifiers` entry in `CreativityHub/Info.plist`

## Activity Log Cleanup Pattern

- Use `ActivityLogCleanupTaskManager` (`CreativityHub/Services/ActivityLogCleanupTaskManager.swift`) as the single owner of cleanup scheduling and execution.
- Register task at app launch and schedule next run daily via BGTaskScheduler identifier `dev.mgorbatyuk.CreativityHub.activitylogcleanup`.
- Run foreground fallback on app foreground entry (`runForegroundCleanupIfNeeded`) to guarantee cleanup even when background execution is delayed.
- Enforce max retention of 6 months via `ActivityLogService.cleanupOlderThanSixMonths(...)`.
- Persist cleanup observability in `user_settings` by upserting:
  - `activity_log_cleanup_last_run_at`
  - `activity_log_cleanup_last_removed_count`
