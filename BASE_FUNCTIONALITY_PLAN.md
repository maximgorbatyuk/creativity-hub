# BASE_FUNCTIONALITY_PLAN.md - CreativeHub Implementation Plan

This document provides a phased implementation plan for building CreativeHub with base functionality copied from Journey Wallet.

## Target App Structure

```
CreativeHub/
├── CreativeHub/                      # Main app target
│   ├── CreativeHubApp.swift          # App entry point
│   ├── MainTabView.swift             # Tab navigation (4 tabs)
│   ├── Assets.xcassets/              # App icons and images
│   ├── Info.plist                    # App configuration
│   ├── CreativeHub.entitlements      # Release entitlements (App Group)
│   ├── CreativeHubDebug.entitlements # Debug entitlements (App Group)
│   ├── en.lproj/Localizable.strings  # English localization
│   ├── ru.lproj/Localizable.strings  # Russian localization
│   ├── kk.lproj/Localizable.strings  # Kazakh localization
│   │
│   ├── Config/                       # Build configuration files
│   │   ├── Base.xcconfig             # Shared configuration
│   │   ├── Debug.xcconfig            # Debug-specific (dev App Group)
│   │   └── Release.xcconfig          # Release-specific (prod App Group)
│   │
│   ├── Features/                     # Feature tab views
│   │   ├── FirstFeatureView.swift
│   │   ├── SecondFeatureView.swift
│   │   └── ThirdFeatureView.swift
│   │
│   ├── UserSettings/                 # Settings screen
│   │   ├── UserSettingsView.swift
│   │   ├── UserSettingsViewModel.swift
│   │   ├── AboutAppSubView.swift
│   │   ├── EditDefaultCurrencyView.swift
│   │   └── iCloudBackupListView.swift
│   │
│   ├── Onboarding/                   # Onboarding flow
│   │   ├── OnboardingView.swift
│   │   ├── OnboardingViewModel.swift
│   │   ├── OnboardingPageView.swift
│   │   ├── OnboardingPageViewModelItem.swift
│   │   └── OnboardingLanguageSelectionView.swift
│   │
│   ├── Services/                     # App services
│   │   ├── AnalyticsService.swift
│   │   ├── EnvironmentService.swift
│   │   ├── DeveloperModeManager.swift
│   │   ├── NotificationManager.swift
│   │   ├── NetworkMonitor.swift
│   │   ├── ColorSchemeManager.swift
│   │   ├── BackupService.swift
│   │   ├── BackgroundTaskManager.swift
│   │   ├── AppVersionChecker.swift
│   │   └── ConfirmationData.swift
│   │
│   └── Shared/                       # Shared components
│       └── ShareSheet.swift
│
├── BusinessLogic/                    # Shared business logic
│   ├── Database/
│   │   ├── DatabaseManager.swift
│   │   ├── MigrationsRepository.swift
│   │   ├── UserSettingsRepository.swift
│   │   ├── DelayedNotificationsRepository.swift
│   │   └── Migrations/
│   │       └── (migration files)
│   │
│   ├── Models/
│   │   ├── Currency.swift
│   │   ├── UserSettings.swift        # AppLanguage, AppColorScheme
│   │   ├── SqlMigration.swift
│   │   └── DelayedNotification.swift
│   │
│   ├── Services/
│   │   └── LocalizationManager.swift  # L() function
│   │
│   ├── Errors/
│   │   ├── RuntimeError.swift
│   │   └── GlobalLogger.swift
│   │
│   └── Helpers/
│       └── AppGroupContainer.swift
│
├── scripts/                          # Development scripts
├── ci_scripts/                       # CI/CD scripts
└── CreativeHub.xcodeproj/
```

---

## Phase 1: Project Foundation

### 1.1 Xcode Project Setup

**Tasks:**
1. Create new iOS App project in Xcode
   - Product Name: `CreativeHub`
   - Bundle ID: `dev.mgorbatyuk.CreativeHub`
   - Interface: SwiftUI
   - Language: Swift
   - Minimum iOS: 18.0

2. Create folder structure:
   ```
   CreativeHub/
   ├── Features/
   ├── UserSettings/
   ├── Onboarding/
   ├── Services/
   └── Shared/

   BusinessLogic/
   ├── Database/
   │   └── Migrations/
   ├── Models/
   ├── Services/
   ├── Errors/
   └── Helpers/
   ```

3. Add folders to Xcode project (Create groups, not folder references)

### 1.2 Add Dependencies

**Swift Package Manager:**
1. Add SQLite.swift: `https://github.com/stephencelis/SQLite.swift`
2. Add Firebase iOS SDK: `https://github.com/firebase/firebase-ios-sdk` (FirebaseAnalytics only)

### 1.3 Create xcconfig Files (Required for App Group & Share Extension)

Create configuration files for build-time variables. This enables Share Extension support later without migration.

**Create folder:** `CreativeHub/Config/`

**File:** `CreativeHub/Config/Base.xcconfig`
```
// Base configuration shared by Debug and Release
GITHUB_REPO_URL = github.com/maximgorbatyuk/creativehub
DEVELOPER_TELEGRAM_LINK = t.me/maximgorbatyuk
APP_STORE_ID = YOUR_APP_STORE_ID
DEVELOPER_NAME = Maxim Gorbatyuk
BUILD_ENVIRONMENT = release
APP_GROUP_IDENTIFIER = group.dev.mgorbatyuk.creativehub
SHARE_EXTENSION_BUNDLE_ID = dev.mgorbatyuk.CreativeHub.ShareExtension
```

**File:** `CreativeHub/Config/Debug.xcconfig`
```
#include "Base.xcconfig"

BUILD_ENVIRONMENT = dev
APP_GROUP_IDENTIFIER = group.dev.mgorbatyuk.creativehub.dev
SHARE_EXTENSION_BUNDLE_ID = dev.mgorbatyuk.CreativeHub.dev.ShareExtension
```

**File:** `CreativeHub/Config/Release.xcconfig`
```
#include "Base.xcconfig"

BUILD_ENVIRONMENT = release
APP_GROUP_IDENTIFIER = group.dev.mgorbatyuk.creativehub
```

**Configure Xcode project:**
1. Select project in navigator → Info tab
2. Under "Configurations", set:
   - Debug → Debug.xcconfig
   - Release → Release.xcconfig

### 1.4 Configure Info.plist

Add these keys to Info.plist (use xcconfig variables where applicable):
```xml
<key>AppGroupIdentifier</key>
<string>$(APP_GROUP_IDENTIFIER)</string>
<key>AppStoreId</key>
<string>$(APP_STORE_ID)</string>
<key>DeveloperName</key>
<string>$(DEVELOPER_NAME)</string>
<key>DeveloperTelegramLink</key>
<string>$(DEVELOPER_TELEGRAM_LINK)</string>
<key>BuildEnvironment</key>
<string>$(BUILD_ENVIRONMENT)</string>
<key>GithubRepoUrl</key>
<string>$(GITHUB_REPO_URL)</string>
```

### 1.5 Create Entitlements Files (Required for App Group)

**File:** `CreativeHub/CreativeHub.entitlements` (Release)
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.application-groups</key>
    <array>
        <string>group.dev.mgorbatyuk.creativehub</string>
    </array>
</dict>
</plist>
```

**File:** `CreativeHub/CreativeHubDebug.entitlements` (Debug)
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.application-groups</key>
    <array>
        <string>group.dev.mgorbatyuk.creativehub.dev</string>
    </array>
</dict>
</plist>
```

**Configure Xcode build settings:**
| Configuration | Code Signing Entitlements |
|---------------|---------------------------|
| Debug | `CreativeHub/CreativeHubDebug.entitlements` |
| Release | `CreativeHub/CreativeHub.entitlements` |

### 1.6 Register App Groups in Apple Developer Portal

1. Go to https://developer.apple.com/account
2. Navigate to Certificates, Identifiers & Profiles → Identifiers
3. Click + and select "App Groups"
4. Register two App Groups:
   - `group.dev.mgorbatyuk.creativehub` (Production)
   - `group.dev.mgorbatyuk.creativehub.dev` (Development)
5. Add these App Groups to your App ID's capabilities

### 1.7 Create .gitignore

Copy from existing `.gitignore` in CreativeHub (already created).

---

## Phase 2: Domain Models

### 2.1 Currency Model

**File:** `BusinessLogic/Models/Currency.swift`

```swift
enum Currency: String, CaseIterable, Codable {
    case usd = "$"
    case kzt = "₸"
    case eur = "€"
    case rub = "₽"
    // Add others as needed

    var shortName: String {
        switch self {
        case .usd: return "🇺🇸 USD"
        case .kzt: return "🇰🇿 KZT"
        case .eur: return "🇪🇺 EUR"
        case .rub: return "🇷🇺 RUB"
        }
    }

    var displayName: String {
        switch self {
        case .usd: return "🇺🇸 US Dollar"
        case .kzt: return "🇰🇿 Kazakhstani Tenge"
        case .eur: return "🇪🇺 Euro"
        case .rub: return "🇷🇺 Russian Ruble"
        }
    }
}
```

### 2.2 UserSettings Models

**File:** `BusinessLogic/Models/UserSettings.swift`

```swift
enum UserSettingKey: String {
    case currency = "currency"
}

enum AppLanguage: String, CaseIterable, Codable {
    case en = "en"
    case ru = "ru"
    case kk = "kk"

    var displayName: String {
        switch self {
        case .en: return "🇬🇧 English"
        case .ru: return "🇷🇺 Русский"
        case .kk: return "🇰🇿 Қазақша"
        }
    }
}

extension UserSettingKey {
    static let language = UserSettingKey(rawValue: "language")!
}

enum AppColorScheme: String, CaseIterable, Codable {
    case system = "system"
    case light = "light"
    case dark = "dark"

    var displayName: String {
        switch self {
        case .system: return L("settings.color_scheme.system")
        case .light: return L("settings.color_scheme.light")
        case .dark: return L("settings.color_scheme.dark")
        }
    }

    var icon: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        }
    }
}
```

### 2.3 SqlMigration Model

**File:** `BusinessLogic/Models/SqlMigration.swift`

```swift
struct SqlMigration {
    var id: Int64?
    var date: Date
}
```

### 2.4 DelayedNotification Model

**File:** `BusinessLogic/Models/DelayedNotification.swift`

```swift
class DelayedNotification: Identifiable {
    var id: Int64?
    var when: Date
    var notificationId: String
    var entityId: Int64?      // Generic entity reference
    var entityType: String?   // Type of entity (for future features)
    var createdAt: Date

    init(
        id: Int64? = nil,
        when: Date,
        notificationId: String,
        entityId: Int64? = nil,
        entityType: String? = nil,
        createdAt: Date? = nil
    ) {
        self.id = id
        self.when = when
        self.notificationId = notificationId
        self.entityId = entityId
        self.entityType = entityType
        self.createdAt = createdAt ?? Date()
    }
}
```

---

## Phase 3: Error Handling & Logging

### 3.1 RuntimeError

**File:** `BusinessLogic/Errors/RuntimeError.swift`

```swift
struct RuntimeError: LocalizedError {
    let message: String

    init(_ message: String) {
        self.message = message
    }

    var errorDescription: String? { message }
}
```

### 3.2 GlobalLogger

**File:** `BusinessLogic/Errors/GlobalLogger.swift`

```swift
import os

class GlobalLogger {
    static let shared = GlobalLogger()

    private let logger: Logger

    private init() {
        logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "-", category: "Global")
    }

    func info(_ message: String) { logger.info("\(message)") }
    func error(_ message: String) { logger.error("\(message)") }
    func debug(_ message: String) { logger.debug("\(message)") }
    func warning(_ message: String) { logger.warning("\(message)") }
}
```

---

## Phase 4: Database Layer

### 4.1 AppGroupContainer

**File:** `BusinessLogic/Helpers/AppGroupContainer.swift`

This implementation reads the App Group identifier from Info.plist (configured via xcconfig), enabling automatic switching between Dev and Production App Groups.

```swift
import Foundation
import os

/// Helper for accessing the shared App Group container.
/// The App Group identifier is read from Info.plist (configured via xcconfig files).
enum AppGroupContainer {
    private static let logger = Logger(subsystem: "AppGroupContainer", category: "Storage")

    /// App Group identifier - read from Info.plist (configured via xcconfig)
    static var identifier: String {
        guard let identifier = Bundle.main.object(forInfoDictionaryKey: "AppGroupIdentifier") as? String else {
            logger.error("AppGroupIdentifier not found in Info.plist")
            fatalError("AppGroupIdentifier not found in Info.plist. Check xcconfig setup.")
        }
        return identifier
    }

    /// Shared container URL for the App Group
    static var containerURL: URL {
        guard let url = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: identifier) else {
            logger.error("App Group '\(identifier)' not configured. Check entitlements.")
            fatalError("App Group '\(identifier)' not configured")
        }
        return url
    }

    /// Database file URL in shared container
    static var databaseURL: URL {
        containerURL.appendingPathComponent("creativehub.sqlite3")
    }

    /// Documents directory in shared container (for file storage)
    static var documentsURL: URL {
        let url = containerURL.appendingPathComponent("Documents")
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    /// Check if App Group is properly configured
    static var isConfigured: Bool {
        guard let identifier = Bundle.main.object(forInfoDictionaryKey: "AppGroupIdentifier") as? String else {
            return false
        }
        return FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: identifier) != nil
    }
}
```

**Important:** This approach:
- Reads App Group ID from Info.plist at runtime
- Automatically uses Dev App Group in Debug builds
- Automatically uses Production App Group in Release builds
- Enables Share Extension to share data with main app (same App Group)
- No migration needed when adding Share Extension later

### 4.2 MigrationsRepository

**File:** `BusinessLogic/Database/MigrationsRepository.swift`

Copy from Journey Wallet with table name `migrations`.

**Key methods:**
- `createTableIfNotExists()`
- `getLatestMigrationVersion() -> Int64`
- `addMigrationVersion()`

### 4.3 UserSettingsRepository

**File:** `BusinessLogic/Database/UserSettingsRepository.swift`

Copy from Journey Wallet with table name `user_settings`.

**Key methods:**
- `createTable()`
- `fetchValue(for key: String) -> String?`
- `upsertValue(key: String, value: String) -> Bool`
- `fetchCurrency() -> Currency`
- `upsertCurrency(_ value: String) -> Bool`
- `fetchLanguage() -> AppLanguage`
- `upsertLanguage(_ value: String) -> Bool`
- `fetchColorScheme() -> AppColorScheme`
- `upsertColorScheme(_ scheme: AppColorScheme) -> Bool`
- `fetchOrGenerateUserId() -> String`
- `fetchAll() -> [(id: Int64, key: String, value: String)]`

### 4.4 DelayedNotificationsRepository

**File:** `BusinessLogic/Database/DelayedNotificationsRepository.swift`

Copy from Journey Wallet, adapt fields for generic use.

**Key methods:**
- `createTable()`
- `insert(_ notification: DelayedNotification) -> Int64?`
- `fetchAll() -> [DelayedNotification]`
- `delete(id: Int64) -> Bool`
- `truncateTable()`

### 4.5 DatabaseManager

**File:** `BusinessLogic/Database/DatabaseManager.swift`

```swift
import Foundation
import SQLite
import os

class DatabaseManager {
    static let MigrationsTableName = "migrations"
    static let UserSettingsTableName = "user_settings"
    static let DelayedNotificationsTableName = "delayed_notifications"

    static let shared = DatabaseManager()

    var migrationRepository: MigrationsRepository?
    var userSettingsRepository: UserSettingsRepository?
    var delayedNotificationsRepository: DelayedNotificationsRepository?

    private var db: Connection?
    private let logger: Logger
    private let latestVersion = 1  // Increment as migrations are added

    private init() {
        logger = Logger(subsystem: "dev.mgorbatyuk.creativehub.database", category: "DatabaseManager")

        do {
            let dbURL = AppGroupContainer.databaseURL
            logger.debug("Database path: \(dbURL.path)")

            self.db = try Connection(dbURL.path)
            guard let dbConnection = db else { return }

            self.migrationRepository = MigrationsRepository(db: dbConnection, tableName: Self.MigrationsTableName)
            self.userSettingsRepository = UserSettingsRepository(db: dbConnection, tableName: Self.UserSettingsTableName)
            self.delayedNotificationsRepository = DelayedNotificationsRepository(db: dbConnection, tableName: Self.DelayedNotificationsTableName)

            self.userSettingsRepository?.createTable()
            migrateIfNeeded()
        } catch {
            logger.error("Unable to setup database: \(error)")
        }
    }

    func deleteAllData() {
        delayedNotificationsRepository?.truncateTable()
        logger.info("All data deleted from database")
    }

    func getDatabaseSchemaVersion() -> Int {
        return latestVersion
    }

    private func migrateIfNeeded() {
        guard let _ = db else { return }

        migrationRepository!.createTableIfNotExists()
        let currentVersion = migrationRepository!.getLatestMigrationVersion()

        if currentVersion == latestVersion { return }

        for version in (Int(currentVersion) + 1)...latestVersion {
            switch version {
            case 1:
                userSettingsRepository!.createTable()
                delayedNotificationsRepository?.createTable()
                _ = userSettingsRepository!.upsertCurrency(Currency.usd.rawValue)
            default:
                break
            }
            migrationRepository!.addMigrationVersion()
        }
    }
}
```

---

## Phase 5: Core Services

### 5.1 LocalizationManager with L() Function

**File:** `BusinessLogic/Services/LocalizationManager.swift`

Copy from Journey Wallet. Provides:
- `LocalizationManager.shared`
- `L(_ key: String) -> String` global function
- `L(_ key: String, language: AppLanguage) -> String`

### 5.2 EnvironmentService

**File:** `CreativeHub/Services/EnvironmentService.swift`

Copy from Journey Wallet. Provides:
- App version info
- App Store ID
- Developer info
- Build environment detection
- `isDevelopmentMode() -> Bool`

### 5.3 DeveloperModeManager

**File:** `CreativeHub/Services/DeveloperModeManager.swift`

Copy from Journey Wallet. Provides:
- Hidden developer mode (15 taps on version)
- `handleVersionTap()`
- `isDeveloperModeEnabled`
- `enableDeveloperMode()` / `disableDeveloperMode()`

### 5.4 NotificationManager

**File:** `CreativeHub/Services/NotificationManager.swift`

Copy from Journey Wallet. Provides:
- Permission handling
- Scheduling notifications
- Canceling notifications

### 5.5 NetworkMonitor

**File:** `CreativeHub/Services/NetworkMonitor.swift`

Copy from Journey Wallet. Provides:
- `isConnected` property
- `connectionType` property
- Network status monitoring

### 5.6 ColorSchemeManager

**File:** `CreativeHub/Services/ColorSchemeManager.swift`

Copy from Journey Wallet. Provides:
- `currentScheme` property
- `setScheme()` method
- `preferredColorScheme` for SwiftUI

### 5.7 AnalyticsService

**File:** `CreativeHub/Services/AnalyticsService.swift`

Copy from Journey Wallet (see GA_GUIDE.md). Provides:
- `trackEvent()`
- `trackScreen()`
- `trackButtonTap()`
- `identifyUser()`

### 5.8 BackupService

**File:** `CreativeHub/Services/BackupService.swift`

Copy from Journey Wallet. Provides:
- `isiCloudAvailable() -> Bool`
- `exportData() async throws -> URL`
- `importData(from url: URL) async throws`
- `createiCloudBackup() async throws -> BackupInfo`
- `listiCloudBackups() async throws -> [BackupInfo]`
- `restoreFromiCloudBackup()` / `deleteiCloudBackup()`

### 5.9 BackgroundTaskManager

**File:** `CreativeHub/Services/BackgroundTaskManager.swift`

Copy from Journey Wallet. Provides:
- Automatic backup scheduling
- `isAutomaticBackupEnabled`
- `lastAutomaticBackupDate`

### 5.10 AppVersionChecker

**File:** `CreativeHub/Services/AppVersionChecker.swift`

Copy from Journey Wallet. Provides:
- `checkAppStoreVersion() async -> Bool?`

### 5.11 ConfirmationData

**File:** `CreativeHub/Services/ConfirmationData.swift`

Copy from Journey Wallet. Helper for confirmation dialogs.

---

## Phase 6: Shared Components

### 6.1 ShareSheet

**File:** `CreativeHub/Shared/ShareSheet.swift`

Copy from Journey Wallet. UIActivityViewController wrapper.

---

## Phase 7: Localization Setup

### 7.1 Create Localization Files

**Structure:**
```
CreativeHub/
├── en.lproj/Localizable.strings
├── ru.lproj/Localizable.strings
└── kk.lproj/Localizable.strings
```

### 7.2 Required Localization Keys

**English (en.lproj/Localizable.strings):**
```
// General
"Skip" = "Skip";
"Next" = "Next";
"Cancel" = "Cancel";
"Confirm" = "Confirm";
"Close" = "Close";
"OK" = "OK";
"Get started" = "Get started";

// Tabs
"tab.first_feature" = "First";
"tab.second_feature" = "Second";
"tab.third_feature" = "Third";
"tab.settings" = "Settings";

// Onboarding
"Welcome to" = "Welcome to";
"Select your language" = "Select your language";
"onboarding.feature1" = "Feature 1";
"onboarding.feature1__subtitle" = "Description of the first feature goes here.";
"onboarding.feature2" = "Feature 2";
"onboarding.feature2__subtitle" = "Description of the second feature goes here.";
"onboarding.feature3" = "Feature 3";
"onboarding.feature3__subtitle" = "Description of the third feature goes here.";

// Settings - Base
"Base settings" = "Base settings";
"Language" = "Language";
"Notifications enabled" = "Notifications enabled";
"In case you want to change this setting, please open app settings" = "To change this setting, open app settings";
"Open settings" = "Open settings";
"Currency" = "Currency";
"It is recommended to set the default currency before adding any expenses." = "Set default currency before adding data.";
"settings.color_scheme" = "Appearance";
"settings.color_scheme.system" = "System";
"settings.color_scheme.light" = "Light";
"settings.color_scheme.dark" = "Dark";

// Settings - iCloud Backup
"iCloud Backup" = "iCloud Backup";
"iCloud Not Available" = "iCloud Not Available";
"Please sign in to iCloud in Settings to enable backups." = "Sign in to iCloud to enable backups.";
"Backup Now" = "Backup Now";
"Creating backup..." = "Creating backup...";
"No Internet Connection" = "No Internet Connection";
"Connect to the internet to create or restore backups." = "Connect to internet for backups.";
"Last backup" = "Last backup";
"View Backup History" = "View Backup History";
"Automatic Backup" = "Automatic Backup";
"Automatic backups to iCloud keep your data safe." = "Automatic backups keep your data safe.";
"Maximum 5 backups kept, older than 30 days auto-deleted." = "Max 5 backups kept, older than 30 days deleted.";

// Settings - Support
"Support" = "Support";
"What is the app about?" = "What is the app about?";
"Start onboarding again" = "Start onboarding again";
"Rate the app" = "Rate the app";
"Contact developer via Telegram" = "Contact developer via Telegram";

// Settings - About
"About app" = "About app";
"App version" = "App version";
"Developer" = "Developer";
"Build" = "Build";
"Developer Mode" = "Developer Mode";

// Settings - Export/Import
"Export & Import" = "Export & Import";
"Export Data..." = "Export Data...";
"Preparing export..." = "Preparing export...";
"Import Data..." = "Import Data...";
"Importing data..." = "Importing data...";
"Export your data to back it up or transfer to another device." = "Export to back up or transfer data.";
"Import will replace all existing data." = "Import will replace all existing data.";
"Export Error" = "Export Error";
"Import Error" = "Import Error";
"Confirm Import" = "Confirm Import";
"Import and Replace All Data" = "Import and Replace All Data";
"Source" = "Source";
"Export Date" = "Export Date";
"App Version" = "App Version";
"Schema Version" = "Schema Version";
"Data Summary" = "Data Summary";

// Settings - Developer
"Developer section" = "Developer section";
"App update available" = "App update available";
"User settings" = "User Settings";

// Placeholder views
"placeholder.title" = "Coming Soon";
"placeholder.subtitle" = "This feature is under development.";
```

**Russian (ru.lproj/Localizable.strings):**
Create translations for all keys above.

**Kazakh (kk.lproj/Localizable.strings):**
Create translations for all keys above.

### 7.3 Enable Localization in Xcode

1. Select project in navigator
2. Go to Info tab → Localizations
3. Add: English, Russian, Kazakh
4. For each `.strings` file, enable all languages in File Inspector

---

## Phase 8: Onboarding Flow

### 8.1 OnboardingPageViewModelItem

**File:** `CreativeHub/Onboarding/OnboardingPageViewModelItem.swift`

```swift
import Foundation
import SwiftUI

struct OnboardingPageViewModelItem: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let description: String
    let color: Color
}
```

### 8.2 OnboardingViewModel

**File:** `CreativeHub/Onboarding/OnboardingViewModel.swift`

```swift
import Foundation

class OnboardingViewModel: ObservableObject {
    var languageManager = LocalizationManager.shared
    var selectedLanguage: AppLanguage

    var pages: [OnboardingPageViewModelItem] = []
    var totalPages: Int = 0

    init() {
        selectedLanguage = languageManager.currentLanguage
        recreatePages()
    }

    func setLanguage(_ language: AppLanguage) {
        selectedLanguage = language
        recreatePages()
    }

    func recreatePages() {
        pages = [
            OnboardingPageViewModelItem(
                icon: "star.fill",
                title: L("onboarding.feature1", language: selectedLanguage),
                description: L("onboarding.feature1__subtitle", language: selectedLanguage),
                color: .orange
            ),
            OnboardingPageViewModelItem(
                icon: "heart.fill",
                title: L("onboarding.feature2", language: selectedLanguage),
                description: L("onboarding.feature2__subtitle", language: selectedLanguage),
                color: .blue
            ),
            OnboardingPageViewModelItem(
                icon: "sparkles",
                title: L("onboarding.feature3", language: selectedLanguage),
                description: L("onboarding.feature3__subtitle", language: selectedLanguage),
                color: .purple
            ),
        ]
        totalPages = 1 + pages.count  // Language page + feature pages
    }
}
```

### 8.3 OnboardingPageView

**File:** `CreativeHub/Onboarding/OnboardingPageView.swift`

Copy from Journey Wallet. Displays single onboarding page with icon, title, description.

### 8.4 OnboardingLanguageSelectionView

**File:** `CreativeHub/Onboarding/OnboardingLanguageSelectionView.swift`

Copy from Journey Wallet, change app name to "CreativeHub".

### 8.5 OnboardingView

**File:** `CreativeHub/Onboarding/OnboardingView.swift`

Copy from Journey Wallet. Main onboarding container with:
- Language selection page
- Feature pages
- Page indicator
- Skip/Next/Get Started buttons

---

## Phase 9: UserSettings Screen

### 9.1 UserSettingsViewModel

**File:** `CreativeHub/UserSettings/UserSettingsViewModel.swift`

Copy from Journey Wallet with all functionality:
- Language management
- Currency management
- Color scheme management
- Export/Import
- iCloud backup
- Developer mode

### 9.2 UserSettingsView

**File:** `CreativeHub/UserSettings/UserSettingsView.swift`

Copy from Journey Wallet with all sections:
1. App Update Banner (conditional)
2. Base Settings (language, notifications, currency, color scheme)
3. iCloud Backup
4. Support
5. About App
6. Export & Import
7. Developer Section (hidden)

### 9.3 AboutAppSubView

**File:** `CreativeHub/UserSettings/AboutAppSubView.swift`

Copy from Journey Wallet, change app name and description.

### 9.4 EditDefaultCurrencyView

**File:** `CreativeHub/UserSettings/EditDefaultCurrencyView.swift`

Create currency selection modal:

```swift
struct EditDefaultCurrencyView: View {
    let selectedCurrency: Currency
    let onSave: (Currency) -> Void

    @Environment(\.dismiss) var dismiss
    @State private var selected: Currency

    init(selectedCurrency: Currency, onSave: @escaping (Currency) -> Void) {
        self.selectedCurrency = selectedCurrency
        self.onSave = onSave
        _selected = State(initialValue: selectedCurrency)
    }

    var body: some View {
        NavigationView {
            List {
                ForEach(Currency.allCases, id: \.self) { currency in
                    Button(action: { selected = currency }) {
                        HStack {
                            Text(currency.displayName)
                            Spacer()
                            if selected == currency {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .foregroundColor(.primary)
                }
            }
            .navigationTitle(L("Currency"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L("Cancel")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L("Save")) {
                        onSave(selected)
                        dismiss()
                    }
                }
            }
        }
    }
}
```

### 9.5 iCloudBackupListView

**File:** `CreativeHub/UserSettings/iCloudBackupListView.swift`

Create backup history list view showing all iCloud backups with restore/delete options.

---

## Phase 10: Tab Navigation & Feature Stubs

### 10.1 PlaceholderTabView

**File:** `CreativeHub/Features/PlaceholderTabView.swift`

```swift
import SwiftUI

struct PlaceholderTabView: View {
    let title: String
    let iconName: String

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: iconName)
                    .font(.system(size: 60))
                    .foregroundColor(.gray)
                Text(L("placeholder.title"))
                    .font(.title)
                    .foregroundColor(.gray)
                Text(L("placeholder.subtitle"))
                    .font(.body)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding()
            }
            .navigationTitle(title)
        }
    }
}
```

### 10.2 Feature Views

**File:** `CreativeHub/Features/FirstFeatureView.swift`
```swift
struct FirstFeatureView: View {
    var body: some View {
        PlaceholderTabView(title: L("tab.first_feature"), iconName: "star.fill")
    }
}
```

**File:** `CreativeHub/Features/SecondFeatureView.swift`
```swift
struct SecondFeatureView: View {
    var body: some View {
        PlaceholderTabView(title: L("tab.second_feature"), iconName: "heart.fill")
    }
}
```

**File:** `CreativeHub/Features/ThirdFeatureView.swift`
```swift
struct ThirdFeatureView: View {
    var body: some View {
        PlaceholderTabView(title: L("tab.third_feature"), iconName: "sparkles")
    }
}
```

### 10.3 MainTabView

**File:** `CreativeHub/MainTabView.swift`

```swift
import SwiftUI

struct MainTabView: View {
    private var viewModel = MainTabViewModel(
        appVersionChecker: AppVersionChecker(environment: EnvironmentService.shared)
    )

    @State private var showAppVersionBadge = false
    @ObservedObject private var loc = LocalizationManager.shared
    @State private var selectedTab: Int = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            // Tab 1: First Feature
            FirstFeatureView()
                .tabItem {
                    Label(L("tab.first_feature"), systemImage: "star.fill")
                }
                .tag(0)

            // Tab 2: Second Feature
            SecondFeatureView()
                .tabItem {
                    Label(L("tab.second_feature"), systemImage: "heart.fill")
                }
                .tag(1)

            // Tab 3: Third Feature
            ThirdFeatureView()
                .tabItem {
                    Label(L("tab.third_feature"), systemImage: "sparkles")
                }
                .tag(2)

            // Tab 4: Settings
            UserSettingsView(showAppUpdateButton: showAppVersionBadge)
                .tabItem {
                    Label(L("tab.settings"), systemImage: "gear")
                }
                .tag(3)
                .badge(showAppVersionBadge ? "!" : nil)
        }
        .tint(Color.orange)
        .id(loc.currentLanguage.rawValue)
        .onAppear {
            Task {
                let result = await viewModel.checkAppVersion()
                showAppVersionBadge = result ?? false
            }
        }
    }
}
```

### 10.4 MainTabViewModel

**File:** `CreativeHub/MainTabViewModel.swift`

```swift
import Foundation

class MainTabViewModel {
    private let appVersionChecker: AppVersionCheckerProtocol

    init(appVersionChecker: AppVersionCheckerProtocol) {
        self.appVersionChecker = appVersionChecker
    }

    func checkAppVersion() async -> Bool? {
        return await appVersionChecker.checkAppStoreVersion()
    }
}
```

---

## Phase 11: App Entry Point

### 11.1 CreativeHubApp

**File:** `CreativeHub/CreativeHubApp.swift`

```swift
import SwiftUI
import UserNotifications
import FirebaseCore

@main
struct CreativeHubApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @AppStorage(UserSettingsViewModel.onboardingCompletedKey) private var isOnboardingComplete = false

    @ObservedObject private var colorSchemeManager = ColorSchemeManager.shared
    private var analytics = AnalyticsService.shared

    var body: some Scene {
        WindowGroup {
            if !isOnboardingComplete {
                OnboardingView(
                    onOnboardingSkipped: {
                        isOnboardingComplete = true
                        analytics.trackEvent("onboarding_skipped")
                    },
                    onOnboardingCompleted: {
                        isOnboardingComplete = true
                        analytics.trackEvent("onboarding_completed")
                    }
                )
                .onAppear { analytics.trackEvent("app_opened") }
                .preferredColorScheme(colorSchemeManager.preferredColorScheme)
            } else {
                MainTabView()
                    .onAppear { analytics.trackEvent("app_opened") }
                    .preferredColorScheme(colorSchemeManager.preferredColorScheme)
            }
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self

        #if DEBUG
        // Skip Firebase in debug
        #else
        FirebaseApp.configure()
        #endif

        Task { @MainActor in
            BackgroundTaskManager.shared.registerBackgroundTasks()
            BackgroundTaskManager.shared.scheduleNextBackup()
        }

        return true
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completion: @escaping (UNNotificationPresentationOptions) -> Void) {
        completion([.banner, .list, .sound])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completion: @escaping () -> Void) {
        completion()
    }
}
```

---

## Phase 12: Firebase & Scripts Setup

### 12.1 Firebase Scripts

Already created in `scripts/` and `ci_scripts/` directories (see GA_GUIDE.md):
- `scripts/generate_firebase_plist.sh`
- `scripts/build_and_distribute.sh`
- `ci_scripts/ci_post_clone.sh`

### 12.2 Create scripts/.env

```bash
export FIREBASE_API_KEY="your-api-key"
export FIREBASE_GCM_SENDER_ID="your-sender-id"
export FIREBASE_APP_ID="your-app-id"
```

---

## Phase 13: Testing & Validation

### 13.1 Build Verification

```bash
cd /Users/maximgorbatyuk/projects/ios/CreativeHub
xcodebuild -project CreativeHub.xcodeproj -scheme CreativeHub \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build
```

### 13.2 Test Checklist

- [ ] App launches without crash
- [ ] Onboarding flow works (language selection, feature pages, skip, complete)
- [ ] Tab navigation works (all 4 tabs)
- [ ] Settings - Language picker changes app language
- [ ] Settings - Currency selection works
- [ ] Settings - Color scheme changes apply
- [ ] Settings - Notifications toggle shows permission state
- [ ] Settings - Developer mode activates after 15 taps on version
- [ ] Settings - Developer section visible in dev mode
- [ ] Settings - Export creates JSON file
- [ ] Settings - Import reads JSON file
- [ ] Localization works for EN, RU, KK

---

## Implementation Order Summary

| Phase | Description | Files Count |
|-------|-------------|-------------|
| 1 | Project Foundation | Project setup |
| 2 | Domain Models | 4 files |
| 3 | Error Handling | 2 files |
| 4 | Database Layer | 5 files |
| 5 | Core Services | 11 files |
| 6 | Shared Components | 1 file |
| 7 | Localization | 3 files |
| 8 | Onboarding | 5 files |
| 9 | UserSettings | 5 files |
| 10 | Tab Navigation | 5 files |
| 11 | App Entry Point | 1 file |
| 12 | Firebase Scripts | Already done |
| 13 | Testing | Validation |

**Total estimated files to create:** ~42 files

---

## Notes for Implementation

1. **Copy files in order** - Later phases depend on earlier phases
2. **Adapt namespaces** - Change "JourneyWallet" references to "CreativeHub"
3. **Update bundle IDs** - Use `dev.mgorbatyuk.CreativeHub`
4. **Test incrementally** - Build after each phase to catch errors early
5. **Use existing guides** - Reference GA_GUIDE.md and USER_SETTINGS_VIEW_GUIDE.md for details
6. **App Group is pre-configured** - Phase 1 sets up App Group for future Share Extension support

---

## Feature Implementation Order & Dependencies

This section shows when additional features from other guide files should be implemented.

### Implementation Timeline

```
Phase 1: Project Foundation
    ├── 1.1-1.2: Xcode setup, dependencies
    ├── 1.3-1.6: xcconfig, Info.plist, Entitlements, App Groups ◄── Required for Share Extension
    └── 1.7: .gitignore

Phase 2-4: Models, Errors, Database
    └── Database uses App Group container (Share Extension ready)

Phase 5: Core Services
    ├── 5.1-5.6: Core services (Localization, Environment, etc.)
    │
    ├── 5.7: AnalyticsService ◄────────────────────────────────────┐
    │   │                                                          │
    │   └── ⚠️  PREREQUISITE: Complete GA_GUIDE.md before this     │
    │       • Create Firebase project                              │
    │       • Create scripts/.env with credentials                 │
    │       • Run ./scripts/generate_firebase_plist.sh             │
    │       • Add GoogleService-Info.plist to Xcode project        │
    │                                                              │
    └── 5.8-5.11: Remaining services                               │
                                                                   │
Phase 6-11: UI Components, Localization, App Entry                 │
    └── App fully functional with analytics                        │
                                                                   │
Phase 12: Firebase & Scripts Setup ◄───────────────────────────────┘
    └── Configure Xcode Cloud secrets for CI/CD

Phase 13: Testing & Validation
    └── Full app testing

────────────────────────────────────────────────────────────────────
AFTER BASE PLAN COMPLETION:
────────────────────────────────────────────────────────────────────

SHARE_EXTENSION_PLAN.md
    └── Can be implemented anytime after Phase 13
    └── App Group already configured in Phase 1.3-1.6
    └── No database migration needed
```

### Feature Dependencies Matrix

| Feature | Guide File | Depends On | Can Start After |
|---------|------------|------------|-----------------|
| **Firebase Analytics** | GA_GUIDE.md | Phase 1.7 (.gitignore) | Phase 1 complete |
| **AnalyticsService** | BASE (Phase 5.7) | GA_GUIDE.md complete | Firebase setup done |
| **Share Extension** | SHARE_EXTENSION_PLAN.md | Phase 13 complete | Full base app working |
| **UserSettings UI** | USER_SETTINGS_VIEW_GUIDE.md | Phase 5 services | Reference during Phase 9 |

### Recommended Implementation Sequence

```
1. ┌─────────────────────────────────────────────────────────────┐
   │ BASE_FUNCTIONALITY_PLAN.md - Phase 1 (Project Foundation)  │
   └─────────────────────────────────────────────────────────────┘
                              │
                              ▼
2. ┌─────────────────────────────────────────────────────────────┐
   │ GA_GUIDE.md - Firebase Setup (Optional but recommended)    │
   │ • Create Firebase project                                   │
   │ • Set up scripts/.env                                       │
   │ • Generate GoogleService-Info.plist                         │
   └─────────────────────────────────────────────────────────────┘
                              │
                              ▼
3. ┌─────────────────────────────────────────────────────────────┐
   │ BASE_FUNCTIONALITY_PLAN.md - Phases 2-13                   │
   │ (AnalyticsService in Phase 5.7 requires Firebase setup)    │
   └─────────────────────────────────────────────────────────────┘
                              │
                              ▼
4. ┌─────────────────────────────────────────────────────────────┐
   │ SHARE_EXTENSION_PLAN.md - All Phases                       │
   │ (Optional - add when sharing functionality needed)          │
   └─────────────────────────────────────────────────────────────┘
```

### Quick Reference: When to Use Each Guide

| Guide | Purpose | When to Read |
|-------|---------|--------------|
| **GA_GUIDE.md** | Firebase Analytics setup | After Phase 1, before Phase 5.7 |
| **USER_SETTINGS_VIEW_GUIDE.md** | Detailed UserSettings implementation | During Phase 9 |
| **SHARE_EXTENSION_PLAN.md** | Add Share Extension | After Phase 13 complete |

### Notes on Skipping Features

**If skipping Firebase Analytics:**
- Remove `AnalyticsService.swift` from Phase 5.7
- Remove Firebase SDK from dependencies (Phase 1.2)
- Remove Firebase initialization from `CreativeHubApp.swift` (Phase 11)
- Remove `scripts/generate_firebase_plist.sh` usage
- Analytics calls in code will need to be stubbed or removed

**If skipping Share Extension:**
- App Group setup (Phase 1.3-1.6) is still recommended
- Enables future extension support without migration
- Can be removed if extension is never planned
