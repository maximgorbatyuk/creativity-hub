# Changelog

All notable changes to CreativityHub since the initial project setup (`000ad10` — Phase 1 + Firebase).

## [Unreleased]

### Added
- **Landing page** — `docs/index.html` with soft brutalism design, CreativityHub color palette (`#573A68`, `#D6AAE7`, `#FEE662`, `#5488C2`, `#04C7D6`), hero section, 9-slide screenshot carousel with feature card click-to-slide interaction, value callout, and footer
- **Landing page CSS** — `docs/brutalism-style.css` with full color token system, responsive layout (860px breakpoint), carousel, card animations, and slide-highlight effect
- **Privacy policy page** — `docs/privacy-policy/index.html` covering data collection, local storage, iCloud backup, export/import, Share Extension, activity logs, Firebase Analytics, notifications, supported languages, and COPPA compliance
- Landing page website guidelines added to `CLAUDE.md`
- Persistent analytics `user_id` — generated on first launch via `UserSettingsRepository.fetchOrGenerateUserId()`, stored in SQLite, included in every event through `AnalyticsService.getGlobalProperties()`
- Updated `CLAUDE.md` to reflect current project structure and features
- **Tag management in User Settings** — `TagsListView`, `TagsListViewModel`, `TagFormView`, `TagRowView` for browsing, creating, editing, and deleting global tags from Settings > Preferences
- Tag management localization strings for English, Russian, and Kazakh
- **Work Logs module** — `WorkLog` model, `work_logs` migration/repository, `WorkLogsListView`, `WorkLogFormView`, preview/row views, and project/checklist integration
- **Activity Log system** — `ActivityLog` model, repository/migration, centralized `ActivityLogService`, and event tracking across project, checklist/items, idea, note, document, expense/category, reminder, and worklog actions (including Share Extension saves)
- **Activity analytics and charts** — `ActivityAnalyticsService`, project detail activity trend chart, and home multi-project weekly activity chart (last 6 months)
- **Activity cleanup background task** — `ActivityLogCleanupTaskManager` with BGTask registration/scheduling and foreground fallback
- Cleanup metadata in `user_settings` — upserted keys for last cleanup datetime and last removed records count
- `ActivityLogRepositoryTests` for insert/fetch ordering, daily aggregation, retention cleanup, and project-scoped deletion
- App update check flow — `AppVersionChecker`, `MainTabViewModel`, and settings update badge wiring
- Launch screen QA preview action in settings and related localization updates

### Changed
- `README.md` expanded with full feature list, website/privacy links, and docs section
- `DatabaseManager` schema upgraded to version `7`; migrations now include document file-path migration, work logs migration, and activity logs migration
- `RandomDataGenerator` now creates activity logs for the last 6 months with realistic density (150-300 records across different days)
- Backup/export/import model wiring updated to include work logs and keep activity logs excluded from payloads
- `EnvironmentService` expanded for centralized build/runtime values (bundle ID, app group identifier, developer/app metadata, App Store link)
- `AppGroupContainer` now resolves group identifier from `EnvironmentService` instead of hardcoded values
- Home/Today dashboard and project detail screens extended with new activity/worklog signals

### Fixed
- Test database bootstrap now mirrors production migration order by applying document file-path and work-log migrations before activity-log migration (`TestDatabaseHelper`)

## 2026-02-20

### Added
- **Automatic backup system** — `BackgroundTaskManager` schedules daily iCloud backups via `BGTaskScheduler`, persists state in `UserDefaults`, retries on foreground entry
- **Upcoming reminders widget** — `UpcomingRemindersView` and `UpcomingRemindersViewModel` for displaying reminders sorted by date with project context
- New accent color and `LaunchScreenColor` asset sets for consistent branding

### Changed
- Expanded `TodayView` dashboard with richer layout, quick stats, and recent projects
- Enhanced `ProjectRowView` visual design and `ProjectsListViewModel` with improved filtering/sorting
- Improved `ReminderRowView` visual hierarchy
- Better `ExpensesListView` filtering and detail view metadata
- Expanded `UserSettingsView` with backup schedule controls
- Enhanced `AnalyticsService` with more comprehensive event tracking
- Simplified `TodayView` by delegating reminders to `UpcomingRemindersView`
- Improved `ProjectContentView` section organization and state management
- Enhanced `BackupService` ZIP handling, path management, and error handling
- Better `DocumentStorageBrowserView` filtering and sorting

## 2026-02-18

### Added
- **Documents module** — `DocumentPickerView` (import from files, photos, camera), `DocumentPreviewView`, `DocumentsListView` with type detection (PDF, JPEG, PNG, HEIC)
- **Ideas module** — `IdeasListView` with grid/list toggle, `IdeaDetailView` with source auto-detection (Instagram, TikTok, Pinterest, YouTube, Website), create/edit form
- **Notes module** — `NotesListView`, `NoteDetailView`, `NoteFormView`
- **Reminders module** — `RemindersListView` with status filtering, `ReminderDetailView`, `ReminderFormView` with date/time picker
- **Expenses module** — `ExpensesListView` with category filtering/sorting, `ExpenseDetailView`, `ExpenseCategoryFormView` for category management
- **Search** — `SearchView` and `SearchViewModel` for global full-text search across all entity types
- **Projects module** — `ProjectDetailView`, `ProjectFormView`, `ProjectsListView` with status filtering (active/completed/archived)
- **Checklists module** — `ChecklistDetailView` with item management and progress tracking, `ChecklistFormView`, `ChecklistItemFormView`
- **Project content dashboard** — `ProjectContentView` showing all project-related entities, `ProjectSelectorView` for switching active projects, `SectionPreviewViews` for Ideas, Notes, Checklists, Documents, Expenses, Reminders
- **Launch screen** — `LaunchScreenView` with branded splash, app icon, version; integrated into `ContentView` with 0.8s fade transition
- **Developer tools** — `DocumentStorageService` and `DocumentStorageBrowserView` for file inspection, `UserSettingsTableView`, `LaunchScreenPreviewView` for QA
- **Developer mode** — `DeveloperModeManager` with 15-tap unlock on app version row
- **Backup service** — `BackupService` for iCloud and safety backup orchestration (ZIP with SQLite + documents, max 3 safety / max 5 iCloud backups)
- **Random data generator** — `RandomDataGenerator` for test data in development
- **Dev/Release branding** — `AppIconDev` asset set, separate bundle identifiers and display names for Debug vs Release builds
- **Shared UI components** — `FilterChip`, `SectionHeaderView`, `CardBackgroundView`, `EmptyStateView`, `ErrorStateView`, `LoadingStateView`, `FormButtonsView`
- `iCloudBackupListView` for browsing and restoring backups
- `AppIconImage` asset for launch screen branding

### Fixed
- iCloud entitlements corrected to use `CloudDocuments` instead of `CloudKit` — fixes backup file availability in-app
- Icon file names and asset catalog metadata encoding
- Production entitlements cleaned up (removed unnecessary entries)

### Changed
- Improved `AppDelegate` logging (switched to `os.Logger`)
- Refined build configuration naming conventions
- Better ViewModel initialization patterns after code review

## 2026-02-17

### Added
- **Onboarding system** — `OnboardingView` with language selection (en, ru, kk), intro pages, and `OnboardingViewModel` for completion state
- **Main navigation** — `MainTabView` with bottom tab bar (Today, Active Project, Projects, Settings)
- **User settings** — `UserSettingsView` and `UserSettingsViewModel`
- **Share Extension foundation** — entitlements, app group configuration, localization strings for share features
- **Localization** — English, Russian, and Kazakh string bundles with 117+ keys
- **Color scheme support** — system/light/dark preference via `AppColorScheme`
- Custom app icons for production builds

## 2026-01-29

### Added
- **Initial project structure** — xcconfig files (Base, Debug, Release), entitlements for Debug and Release with iCloud support
- **Analytics** — `AnalyticsService` with Firebase (Release builds only, DEBUG logs locally)
- **App entry points** — `CreativityHubApp` with `AppDelegate`, `ContentView` as root view
- App icon and accent color assets
