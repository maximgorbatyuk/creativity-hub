# CreativityHub — Remaining Implementation

Last updated: 2026-02-17

## What Is Done

- Project foundation (Xcode project, dependencies, configs, entitlements)
- Domain models (Project, Checklist, ChecklistItem, Idea, Note, Expense, Category, Tag)
- Error handling and logging (AppError, RuntimeError, AppLogger)
- Database layer (DatabaseManager, repositories, migrations, App Group container)
- Core services (LocalizationManager, AnalyticsService, ColorSchemeManager)
- Shared UI components (EmptyStateView, ErrorStateView, LoadingView)
- Localization setup (en/ru/kk) with `L()` function
- Onboarding flow (language selection + feature walkthrough)
- Settings module (language, currency, color scheme, about section)
- Tab navigation with feature stubs (Today, Projects, Search, Settings)
- App entry point wiring (ContentView, CreativityHubApp, AppDelegate)
- Firebase Analytics setup (scripts, AnalyticsService, conditional init) — Xcode Cloud secrets pending
- Share Extension target (wiring, entitlements, xcconfig, embedding)
- Share Extension UX (input parsing, form UI, persistence, localization)
- Appearance switching (System/Light/Dark)

---

## Remaining Work

### 1. Project CRUD + Detail View

Project is the aggregate root — all features are scoped by `projectId`.

- Project list view with create/edit/delete
- Project detail view with segmented sections: Checklists, Ideas, Documents, Notes, Budget
- Project status management (active/completed/archived)
- Optional cover image/color
- Optional start/target dates
- Pin favorites and sort projects
- Progress percentage from checklist completion
- Shared UI: `MoveToProjectSheet` (reusable for all entities)

Source reference: `journey-wallet/JourneyWallet/Journey/*`

### 2. Checklists

- Checklist list + detail views per project
- Checklist item CRUD with due date, priority, estimated cost, notes
- One-tap completion toggle
- Progress indicators (checklist and project level)
- Drag/drop reorder
- Filters: all, pending, completed
- Move checklist to another project
- Shared UI: `FilterChip` component

Source reference: `journey-wallet/JourneyWallet/Checklist/*`

### 3. Ideas

- Idea list/detail views per project
- URL support + metadata (title, preview image, source domain)
- Auto-detect source type (Instagram, Pinterest, YouTube, TikTok, etc.)
- Done/not-done state
- Open/copy/share URL actions
- Grid/list layout toggle
- Notes and tags on ideas
- Move between projects

Source reference: `journey-wallet/JourneyWallet/Idea/*`

### 4. Notes

- Note list/form per project
- Note CRUD (plain text for MVP)
- Pin/unpin important notes
- Sort by creation/update date
- Move between projects

Source reference: `journey-wallet/JourneyWallet/Note/*`

### 5. Documents

Requires a new `Document` model, repository, and migration table. Currently the Share Extension saves documents as Note placeholders.

- Document model + `DocumentsRepository` + migration
- `DocumentService` for file storage (App Group documents directory)
- Import from Files, Photos, Camera
- Preview flows (PDF, image, unsupported fallback)
- Filter chips: all/pdf/images
- Custom names, rename, share, delete
- Move between projects
- Migrate existing Note placeholders to Document entries

Source reference: `journey-wallet/JourneyWallet/Document/*`, `journey-wallet/BusinessLogic/Services/DocumentService.swift`

### 6. Budget and Expenses

- Expense CRUD per project
- Category management per project (name, budget limit, color)
- Totals by currency (always use `Decimal`)
- Category breakdown display
- Spent vs remaining with warnings
- Expense status: planned, paid, refunded
- Receipt photo attachment (optional)
- Move between projects
- Export report (PDF/CSV — post-MVP)

Source reference: `journey-wallet/JourneyWallet/Budget/*`

### 7. Reminders

Requires a new `Reminder` model, repository, and migration table.

- Reminder model + `RemindersRepository` + migration
- `ReminderService` + `NotificationManager` for local notification scheduling/cancel
- Reminder entity types: `custom`, `checklistItem`, `idea`, `expense`
- Grouped sections: overdue, today, tomorrow, upcoming
- Complete/incomplete toggles
- Edit/delete
- Project association

Source reference: `journey-wallet/JourneyWallet/Notifications/*`, `journey-wallet/JourneyWallet/Services/ReminderService.swift`

### 8. Today View

Currently a stub. Should include:

- Search bar (quick access to universal search)
- Top due tasks (from checklists with due dates)
- Top active projects summary
- Quick "Create Project" action

### 9. Universal Search

Currently a stub. Should include:

- Search across projects, checklist items, ideas, expenses, and notes
- Filter by content type, project, date range
- Recent searches and suggestions
- Spotlight integration (post-MVP)

### 10. Backup/Restore + Import/Export

- `ExportModels` adapted for CreativityHub entities (Project, Checklist, ChecklistItem, Idea, Note, Document metadata, Expense, Reminder, UserSettings)
- `BackupService` for iCloud backup/restore
- `iCloudBackupListView` for backup management
- `BackgroundTaskManager` for automatic background backups (register in AppDelegate, align with Info.plist)
- Import/export JSON controls in Settings
- Validate iCloud capability alignment in entitlements

Source reference: `journey-wallet/JourneyWallet/Services/BackupService.swift`, `journey-wallet/BusinessLogic/Models/ExportModels.swift`

### 11. Developer Mode

- `DeveloperModeManager` (15-tap activation on version label)
- Hidden Settings section with debug tools:
  - Notification test utilities
  - Migration reset utility
  - UserSettings table viewer
  - Document storage browser
- Exclude travel-specific random data generator; rewrite for CreativityHub entities if needed

Source reference: `journey-wallet/JourneyWallet/Services/DeveloperModeManager.swift`, `journey-wallet/JourneyWallet/Developer/*`

### 12. Unit Tests

No test target exists yet. Add XCTest target and cover:

- Repository operations (CRUD for each entity)
- ViewModel validation logic
- InputParser (Share Extension)
- Localization key coverage

### 13. Xcode Cloud Secrets

Firebase Analytics GA_GUIDE step 8 — configure environment secrets in App Store Connect for CI/CD builds.

---

## Migration Strategy

Use **copy-then-adapt** from `journey-wallet`:
- Copy proven modules
- Rename domain references (`journey` -> `project`, `journeyId` -> `projectId`)
- Remove travel-only dependencies
- Integrate with CreativityHub app shell
- Validate incrementally after each feature

## Recommended Execution Order

1. Project CRUD + detail view (required by all features)
2. Checklists (most complex, enables progress tracking)
3. Ideas (enables inspiration capture)
4. Notes (simple CRUD)
5. Documents (new model + file storage)
6. Budget/Expenses (category management + currency)
7. Reminders (local notifications)
8. Today view + Universal search (aggregation views)
9. Backup/Restore + Import/Export
10. Developer mode
11. Unit tests
12. Xcode Cloud secrets

## MVP Must-Have (from master plan)

- [x] Local database persistence
- [ ] Project creation/management
- [ ] Basic checklist completion tracking
- [ ] Save links as ideas with metadata
- [ ] Simple budget tracking (budget, expenses, balance)
- [ ] Basic plain-text notes
- [ ] Universal search across local data
