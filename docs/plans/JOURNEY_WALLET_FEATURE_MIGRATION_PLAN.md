# Journey Wallet -> CreativityHub Migration Plan

## Goal

Port these **functional features** from `journey-wallet` to `CreativityHub`:
- Checkboxes (checklists + checklist items)
- Ideas
- Notes
- Documents
- Budget
- Reminders
- Share Extension (share from other apps into CreativityHub)

And these **non-functional features**:
- Appearance (light/dark/system)
- Backup/restore (iCloud + automatic background backups)
- Import/export (JSON data transfer)
- Developer mode (hidden tools)

This plan is based on analysis of the current `journey-wallet` implementation and current `CreativityHub` state.

---

## Core Domain Rule (Required)

`Project` is the aggregate root in CreativityHub (same role as `Journey` in journey-wallet).

Every migrated feature entity must belong to exactly one `Project` via `projectId`:
- `Checklist`
- `ChecklistItem` (through parent checklist)
- `Idea`
- `Note`
- `Document`
- `Expense`
- `Reminder`

Implementation rule:
- No standalone feature records without a parent `Project`.
- Feature lists and statistics are always loaded in Project scope.

---

## What Was Analyzed

### Source (`journey-wallet`) feature modules
- Checklists: `JourneyWallet/Checklist/*`, `BusinessLogic/Models/Checklist*.swift`, `BusinessLogic/Database/Repositories/ChecklistsRepository.swift`, `BusinessLogic/Database/Repositories/ChecklistItemsRepository.swift`
- Ideas: `JourneyWallet/Idea/*`, `BusinessLogic/Models/Idea.swift`, `BusinessLogic/Database/Repositories/IdeasRepository.swift`
- Notes: `JourneyWallet/Note/*`, `BusinessLogic/Models/Note.swift`, `BusinessLogic/Database/Repositories/NotesRepository.swift`
- Documents: `JourneyWallet/Document/*`, `BusinessLogic/Models/Document.swift`, `BusinessLogic/Services/DocumentService.swift`, `BusinessLogic/Database/Repositories/DocumentsRepository.swift`
- Budget: `JourneyWallet/Budget/*`, `BusinessLogic/Models/Expense.swift`, `BusinessLogic/Models/Currency.swift`, `BusinessLogic/Database/Repositories/ExpensesRepository.swift`
- Reminders: `JourneyWallet/Notifications/*`, `JourneyWallet/Services/NotificationManager.swift`, `JourneyWallet/Services/ReminderService.swift`, `BusinessLogic/Models/Reminder.swift`, `BusinessLogic/Database/Repositories/RemindersRepository.swift`
- Share Extension: `ShareExtension/*`, `ShareExtension/Models/*`, `ShareExtensionDev/*`

### Source non-functional modules
- Appearance: `BusinessLogic/Models/UserSettings.swift`, `BusinessLogic/Database/UserSettingsRepository.swift`, `JourneyWallet/Services/ColorSchemeManager.swift`, `JourneyWallet/JourneyWalletApp.swift`, `JourneyWallet/UserSettings/UserSettingsView*.swift`
- Backup/restore + import/export: `BusinessLogic/Models/ExportModels.swift`, `JourneyWallet/Services/BackupService.swift`, `JourneyWallet/Services/BackgroundTaskManager.swift`, `JourneyWallet/UserSettings/iCloudBackupListView.swift`, `JourneyWallet/UserSettings/UserSettingsView*.swift`, `JourneyWallet/Services/NetworkMonitor.swift`
- Developer mode: `JourneyWallet/Services/DeveloperModeManager.swift`, `JourneyWallet/Developer/*`, hidden section in `JourneyWallet/UserSettings/UserSettingsView.swift`

### Current target (`CreativityHub`) baseline
- Minimal app shell only: `CreativityHub/CreativityHubApp.swift`, `CreativityHub/ContentView.swift`, `CreativityHub/Services/AnalyticsService.swift`
- `BusinessLogic/` folder exists but is mostly empty
- SQLite + Firebase packages are already configured in project
- Info/entitlements/background modes are present but still need alignment with migrated services

---

## Key Findings That Impact Implementation

1. In `journey-wallet`, all requested features are scoped by `journeyId`.
   - CreativityHub must introduce a root container entity (recommended: `Project`) before feature porting.

2. Requested features are not isolated; they depend on shared infrastructure:
   - `DatabaseManager`, migrations, repositories, localization `L()`, settings storage, app group storage helpers.

3. Backup/import/export currently serialize DB metadata to JSON.
   - Document file binaries are not embedded in export JSON.
   - Decide whether to keep parity (fastest) or improve (ZIP with files + JSON manifest).

4. Developer mode in source includes tools that depend on travel-only entities.
   - For CreativityHub scope, keep core dev mode + storage/tools; exclude or rewrite travel-specific random data generator.

5. iCloud backup service uses file-based ubiquity container behavior.
   - Entitlements/Info values in CreativityHub must be checked and aligned for the exact backup approach.

6. Share Extension in source uses shared App Group storage and shared DB repositories.
   - Extension + host app must use the same App Group and database schema to avoid inconsistent writes.

---

## Migration Strategy

Use a **copy-then-adapt** strategy:
- Copy proven modules from `journey-wallet`
- Rename domain references (`journey` -> `project`)
- Remove travel-only dependencies
- Integrate with CreativityHub app shell and settings
- Validate incrementally after each phase

---

## Phased Implementation Plan

## Phase 0 - Scope Lock and Domain Mapping

### Tasks
- Confirm root entity mapping:
  - `Journey` -> `Project`
  - `journeyId` -> `projectId`
- Define in-scope entities for export/import:
  - `Project`, `Checklist`, `ChecklistItem`, `Idea`, `Note`, `Document` (metadata), `Expense`, `Reminder`, `UserSettings`
- Freeze out-of-scope travel features:
  - transport, hotel, car rental, places, roadmap

### Deliverable
- Finalized naming and migration rules used across all phases.

---

## Phase 1 - Core Infrastructure (Must Exist Before Features)

### Tasks
- Implement BusinessLogic foundation in CreativityHub:
  - `BusinessLogic/Helpers/AppGroupContainer.swift`
  - `BusinessLogic/Database/DatabaseManager.swift`
  - `BusinessLogic/Database/MigrationsRepository.swift`
  - `BusinessLogic/Database/UserSettingsRepository.swift`
  - `BusinessLogic/Services/LocalizationManager.swift` + global `L()`
  - `BusinessLogic/Models/UserSettings.swift` (`AppLanguage`, `AppColorScheme`)
  - `BusinessLogic/Models/Currency.swift`
  - `BusinessLogic/Errors/RuntimeError.swift`
- Add base `Project` model + repository + migration table.
- Add migrations for all requested feature tables:
  - projects, checklists, checklist_items, ideas, notes, documents, expenses, reminders
- Enforce relational ownership at repository/service level:
  - all insert/fetch/update/delete methods are project-scoped (`projectId`)
  - no cross-project leakage in queries

### Deliverable
- App launches with DB + localization + settings read/write functioning.

---

## Phase 2 - Project Container + Navigation Skeleton

### Tasks
- Build minimal project shell (required by all requested features):
  - Project list (CRUD)
  - Project detail with section entry points
  - Project selector pattern for all feature sections
- Replace current `ContentView` shell with production navigation:
  - `MainTabView` (or equivalent)
  - Settings tab
  - Project detail route
- Port reusable shared UI needed by requested features:
  - `FilterChip`
  - `ShareSheet`
  - `MoveToProjectSheet` (adapted from `MoveToJourneySheet`)

### Deliverable
- User can create/select a project and open empty sections for all requested features.
- All feature screens are reachable only through selected Project context.

---

## Phase 3 - Functional Feature Ports

Implement in this order for lowest dependency friction.

### 3.1 Checkboxes

#### Source reference
- `JourneyWallet/Checklist/*`

#### Tasks
- Port and adapt models/repositories/viewmodels/views.
- Ensure all checklist flows are project-attached:
  - checklist has `projectId`
  - checklist item reads/writes only through checklist/project context
- Keep behavior parity:
  - checklist list + detail
  - item add/edit/delete/toggle
  - pending/completed filters
  - progress indicators
  - drag/drop reorder
  - move checklist to another project

#### Done criteria
- Full CRUD + filtering + reorder + progress works per project.

### 3.2 Ideas

#### Source reference
- `JourneyWallet/Idea/*`

#### Tasks
- Port idea list/detail/form module.
- Ensure ideas are strictly project-scoped (`projectId` in all operations).
- Adapt domain and remove roadmap-specific coupling for first pass (optional follow-up if needed).
- Keep parity:
  - done/not done state
  - URL support + open/copy/share
  - move to another project

#### Done criteria
- Idea lifecycle and interactions are functional and localized.

### 3.3 Notes

#### Source reference
- `JourneyWallet/Note/*`

#### Tasks
- Port note list/form module and note repository/model.
- Ensure notes are strictly project-scoped (`projectId` in all operations).
- Keep parity:
  - note CRUD
  - pin/unpin important notes (if retained from source behavior)
  - simple sort by creation/update date
  - move note between projects

#### Done criteria
- Notes are fully functional as first-class project objects.

### 3.4 Documents

#### Source reference
- `JourneyWallet/Document/*`, `BusinessLogic/Services/DocumentService.swift`

#### Tasks
- Port document metadata model/repository and file storage service.
- Ensure document metadata includes `projectId` and storage path strategy remains project-isolated.
- Port picker flows (Files, Photos, Camera).
- Port preview flows (PDF, image, unsupported fallback).
- Keep parity:
  - custom names
  - filter chips (all/pdf/images)
  - share/rename/delete
  - move between projects

#### Done criteria
- Import/view/manage files end-to-end for each project.

### 3.5 Budget

#### Source reference
- `JourneyWallet/Budget/*`

#### Tasks
- Port expenses model/repository/viewmodel/views.
- Ensure every expense is attached to one project (`projectId`) and totals are computed per project by default.
- Keep currency handling with `Decimal` only.
- Keep parity:
  - expense CRUD
  - category filtering
  - totals by currency
  - category breakdown chips
  - move expense between projects

#### Done criteria
- Budget screen reflects correct totals and filtered lists.

### 3.6 Reminders

#### Source reference
- `JourneyWallet/Notifications/*`, `ReminderService`, `NotificationManager`

#### Tasks
- Port reminders model/repository/viewmodel/views.
- Ensure reminders always belong to one project (`projectId`) and grouping/filtering defaults to that scope.
- Port local notification scheduling/cancel flow.
- Adapt `ReminderEntityType` from travel labels to CreativityHub labels (recommended: `custom`, `checklistItem`, `idea`, `expense`).
- Keep parity:
  - grouped reminder sections (overdue/today/tomorrow/etc.)
  - complete/incomplete toggles
  - edit/delete
  - project association

#### Done criteria
- Reminder CRUD + local notification behavior works reliably.

---

## Phase 4 - Non-Functional Feature Ports

### 4.1 Appearance

#### Tasks
- Port color scheme settings and manager.
- Apply `.preferredColorScheme(...)` at app root.
- Ensure runtime switching from settings works immediately.

#### Done criteria
- User can switch System/Light/Dark and app updates live.

### 4.2 Backup/Restore + Import/Export

#### Tasks
- Port and adapt:
  - `ExportModels` (trim to CreativityHub entities)
  - `BackupService`
  - `iCloudBackupListView`
  - import/export controls in `UserSettingsView`
- Port automatic backups:
  - `BackgroundTaskManager`
  - register task in `AppDelegate`
  - align BG task identifier with `Info.plist`
- Validate iCloud capability alignment in entitlements/Apple portal.

#### Done criteria
- Manual backup works.
- Backup list loads/restores/deletes.
- Import/export JSON works.
- Automatic backup scheduling works when enabled.

### 4.3 Developer Mode

#### Tasks
- Port `DeveloperModeManager` (15 taps activation).
- Port hidden settings section with safe subset:
  - notification test utilities
  - migration reset utility
  - user_settings table viewer
  - document storage browser (`JourneyWallet/Developer/*`, renamed)
- Exclude or rewrite random data generator for CreativityHub entities only.

#### Done criteria
- Developer mode can be activated/deactivated and exposes debug tools only when enabled.

### 4.4 Share Extension Port

#### Source reference
- `ShareExtension/ShareViewController.swift`
- `ShareExtension/ShareViewModel.swift`
- `ShareExtension/ShareView.swift`
- `ShareExtension/Models/ShareEntityType.swift`
- `ShareExtension/Models/SharedContentType.swift`
- `ShareExtension/Info.plist`, `ShareExtension*.entitlements`

#### Tasks
- Add a new Share Extension target in `CreativityHub.xcodeproj` and embed it in the app target.
- Configure extension target build settings to use xcconfig variables:
  - `PRODUCT_BUNDLE_IDENTIFIER = $(SHARE_EXTENSION_BUNDLE_ID)`
  - `INFOPLIST_FILE` for extension
  - debug/release extension entitlements
- Port extension UI + logic (`ShareViewController`, `ShareViewModel`, `ShareView`).
- Port extension content model types (`SharedContentType`, `ContentAnalyzer`) and adapt entity mapping for CreativityHub domain.
- Recommended entity mapping for extension text/URL flow:
  - `.note`, `.idea`, `.checklistItem`, `.reminder`, `.expense`
  - file flow always creates `Document` entries
- Ensure extension uses shared BusinessLogic repositories through `DatabaseManager` and App Group container path.
- Set extension `Info.plist` activation rules to support:
  - files (including PDF/images), text, web URL
  - max file/image counts aligned with UX expectations
- Add extension localization keys for all share screens/messages.
- Validate both Debug and Release extension signing/app-group alignment.

#### Done criteria
- From Safari/Files/Photos, user can share into CreativityHub and save successfully to selected project.
- Shared content appears immediately in app sections (Documents/Ideas/etc.).
- Extension works in Debug and Release with no entitlement/app-group errors.

---

## Phase 5 - Integration, Cleanup, and QA

### Tasks
- Wire analytics events for all migrated flows.
- Remove leftover `journey-wallet` naming constants/identifiers.
- Add all required localization keys for migrated features in supported languages.
- Perform schema upgrade testing from clean install and upgrade scenarios.
- Run full build and manual regression suite.

### Done criteria
- All requested functional and non-functional features (including Share Extension) are available in CreativityHub with stable navigation and settings integration.

---

## Acceptance Checklist

- [ ] Projects can host checklists, ideas, notes, documents, budget entries, reminders.
- [ ] `Project` is implemented as the required high-level object (aggregate root), equivalent to `Journey` in journey-wallet.
- [ ] All migrated entities are persisted and queried with `projectId` ownership.
- [ ] Checklists support filtering, progress, and reorder.
- [ ] Ideas support done-state, URL handling, share, move.
- [ ] Notes support CRUD and remain project-scoped.
- [ ] Documents support Files/Photos/Camera import, preview, rename, share, delete.
- [ ] Budget supports expense CRUD, category filtering, totals by currency.
- [ ] Reminders support local notifications and grouping logic.
- [ ] Share Extension can save files/text/URLs into selected project.
- [ ] Appearance switch (System/Light/Dark) works instantly.
- [ ] Export/import works for in-scope entities.
- [ ] iCloud backup/restore and automatic backups work.
- [ ] Developer mode activates via version taps and reveals debug tools.

---

## Risk Register and Mitigations

1. **Domain coupling risk** (`journeyId` everywhere)
   - Mitigation: perform systematic `journey` -> `project` replacement early (Phase 0/1).

2. **iCloud capability mismatch risk**
   - Mitigation: align entitlements + `Info.plist` + BG task identifier before enabling backup QA.

3. **Document export completeness risk**
   - Mitigation: explicitly decide parity vs improved export package with file binaries.

4. **Developer tools referencing removed travel modules**
   - Mitigation: keep only scope-safe tools first; add synthetic data generator later for CreativityHub entities.

5. **Localization regressions from copied hardcoded strings**
   - Mitigation: enforce `L()` for all user-facing text during each phase.

6. **Share Extension entitlement/config mismatch risk**
   - Mitigation: verify host app + extension use the same App Group per build configuration and validate signed build on device.

---

## Recommended Execution Order (Condensed)

1. Core infrastructure + Project entity
2. Navigation shell + settings baseline
3. Checklists -> Ideas -> Notes -> Documents -> Budget -> Reminders
4. Appearance -> Backup/Restore -> Import/Export -> Developer mode
5. Share Extension target + flows + localization
6. Localization completion + QA hardening
