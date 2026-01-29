# USER_SETTINGS_VIEW_GUIDE.md - User Settings Screen Implementation Guide

This guide provides detailed instructions for implementing a User Settings screen in CreativeHub, following the pattern from Journey Wallet.

## Overview

The User Settings screen is built using:
- **SwiftUI Form** with multiple sections
- **MVVM architecture** with `UserSettingsViewModel`
- **Multiple services** for different functionality
- **Developer mode** activated by tapping version 15 times

## UI Structure

### Sections Overview

| Section | Description | Always Visible |
|---------|-------------|----------------|
| App Update Banner | Shows when update available | Conditional |
| Base Settings | Language, notifications, currency, color scheme | Yes |
| iCloud Backup | Manual/automatic backup, restore | Yes |
| Support | About app, onboarding, rate app, contact | Yes |
| About App | Version, developer, build info | Yes |
| Export & Import | Data export/import to file | Yes |
| Developer Section | Debug tools, test data | Only in developer mode |

---

## Section Details

### 1. App Update Banner (Conditional)

Shows at top when `showAppUpdateButton = true`:

```swift
if showAppUpdateButton {
    HStack {
        Text(L("App update available"))
            .fontWeight(.semibold)
        Spacer()
        Button(action: { /* open App Store */ }) {
            Image(systemName: "arrow.down.circle.fill")
                .foregroundColor(.orange)
                .font(.system(size: 28))
        }
    }
    .listRowBackground(Color.yellow.opacity(0.2))
}
```

### 2. Base Settings Section

Contains:
- **Language Picker** - `Picker` with `AppLanguage.allCases`
- **Notifications Toggle** - Disabled toggle + "Open settings" button
- **Currency Selection** - Button that opens currency modal
- **Color Scheme Picker** - `Picker` with `AppColorScheme.allCases`

```swift
Section(header: Text(L("Base settings"))) {
    // Language picker
    Picker(L("Language"), selection: $viewModel.selectedLanguage) {
        ForEach(AppLanguage.allCases, id: \.self) { lang in
            Text(lang.displayName).tag(lang)
        }
    }
    .pickerStyle(MenuPickerStyle())

    // Notifications row with toggle + button
    VStack {
        HStack {
            Text(L("Notifications enabled"))
            Spacer()
            Toggle("", isOn: $isNotificationsEnabled)
                .disabled(true)
        }
        HStack {
            Text(L("Open app settings to change"))
                .font(.caption)
            Spacer()
            Button(L("Open settings")) { openSettings() }
        }
    }

    // Currency row
    VStack {
        HStack {
            Text(L("Currency"))
            Spacer()
            Button(viewModel.defaultCurrency.shortName) {
                showEditCurrencyModal = true
            }
        }
        Text(L("Set currency before adding expenses"))
            .font(.caption)
            .foregroundColor(.secondary)
    }

    // Color scheme picker
    Picker(L("Color Scheme"), selection: $viewModel.selectedColorScheme) {
        ForEach(AppColorScheme.allCases, id: \.self) { scheme in
            Label(scheme.displayName, systemImage: scheme.icon).tag(scheme)
        }
    }
}
```

### 3. iCloud Backup Section

Contains:
- Warning if iCloud unavailable
- "Backup Now" button with progress indicator
- Network unavailable warning
- Last backup timestamp
- "View Backup History" navigation button
- Automatic backup toggle
- Info text about backup policy

```swift
Section(header: Text(L("iCloud Backup"))) {
    // iCloud not available warning
    if !viewModel.isiCloudAvailable() {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
            VStack(alignment: .leading) {
                Text(L("iCloud Not Available"))
                    .fontWeight(.semibold)
                Text(L("Sign in to iCloud in Settings"))
                    .font(.caption)
            }
        }
    }

    // Backup button
    Button(action: { Task { await viewModel.createiCloudBackup() } }) {
        HStack {
            if viewModel.isBackingUp {
                ProgressView()
            } else {
                Image(systemName: "icloud.and.arrow.up")
            }
            Text(viewModel.isBackingUp ? L("Creating backup...") : L("Backup Now"))
        }
    }
    .disabled(!viewModel.isiCloudAvailable() || viewModel.isBackingUp)

    // Automatic backup toggle
    Toggle(isOn: $viewModel.isAutomaticBackupEnabled) {
        HStack {
            Image(systemName: "clock.arrow.circlepath")
            Text(L("Automatic Backup"))
        }
    }
}
```

### 4. Support Section

Contains buttons for:
- "What is the app about?" - Opens AboutAppSubView modal
- "Start onboarding again" - Resets onboarding flag
- "Rate the app" - Uses StoreKit `requestReview`
- "Contact developer via Telegram" - Opens Telegram link

```swift
Section(header: Text(L("Support"))) {
    Button(action: { showingAppAboutModal = true }) {
        HStack {
            Image(systemName: "questionmark.circle.fill").foregroundColor(.cyan)
            Text(L("What is the app about?"))
        }
    }

    Button(action: {
        UserDefaults.standard.removeObject(forKey: UserSettingsViewModel.onboardingCompletedKey)
    }) {
        HStack {
            Image(systemName: "figure.wave").foregroundColor(.green)
            Text(L("Start onboarding again"))
        }
    }

    Button { requestReview() } label: {
        HStack {
            Image(systemName: "star.fill").foregroundColor(.yellow)
            Text(L("Rate the app"))
        }
    }

    Button { openTelegramLink() } label: {
        HStack {
            Image(systemName: "ellipses.bubble.fill").foregroundColor(.blue)
            Text(L("Contact developer via Telegram"))
        }
    }
}
```

### 5. About App Section

Shows:
- App version (tappable to enable developer mode)
- Developer name
- Build type (if development)
- Developer mode indicator (if enabled)

```swift
Section(header: Text(L("About app"))) {
    // Version row - TAP TO ENABLE DEV MODE
    Button(action: { viewModel.handleVersionTap() }) {
        HStack {
            Label(L("App version"), systemImage: "info.circle")
            Spacer()
            Text(environment.getAppVisibleVersion())
        }
    }
    .buttonStyle(.plain)

    HStack {
        Label(L("Developer"), systemImage: "person")
        Spacer()
        Text(environment.getDeveloperName())
    }

    if viewModel.isDevelopmentMode() {
        HStack {
            Label(L("Build"), systemImage: "star.circle")
            Spacer()
            Text("Development")
        }
    }

    if viewModel.isSpecialDeveloperModeEnabled() {
        Button(action: { developerMode.disableDeveloperMode() }) {
            HStack {
                Label(L("Developer Mode"), systemImage: "hammer.fill")
                    .foregroundColor(.orange)
                Spacer()
                Text("Enabled").foregroundColor(.orange)
            }
        }
    }
}
```

### 6. Export & Import Section

Contains:
- Export button with progress
- Import button with progress
- Info/warning text

```swift
Section(header: Text(L("Export & Import"))) {
    Button(action: { Task { exportData() } }) {
        HStack {
            if viewModel.isExporting {
                ProgressView()
            } else {
                Image(systemName: "square.and.arrow.up").foregroundColor(.blue)
            }
            Text(viewModel.isExporting ? L("Preparing export...") : L("Export Data..."))
        }
    }

    Button(action: { showImportFilePicker = true }) {
        HStack {
            if viewModel.isImporting {
                ProgressView()
            } else {
                Image(systemName: "square.and.arrow.down").foregroundColor(.orange)
            }
            Text(viewModel.isImporting ? L("Importing...") : L("Import Data..."))
        }
    }

    VStack(alignment: .leading, spacing: 4) {
        Text(L("Export to back up or transfer data"))
            .font(.caption).foregroundColor(.secondary)
        Text(L("Import will replace all existing data"))
            .font(.caption).foregroundColor(.red)
    }
}
```

### 7. Developer Section (Hidden by Default)

Only visible when `viewModel.isSpecialDeveloperModeEnabled()`:

```swift
if viewModel.isSpecialDeveloperModeEnabled() {
    Section(header: Text(L("Developer section"))) {
        Button("Request Permission") { NotificationManager.shared.requestPermission() }
        Button("Send Notification Now") { /* test notification */ }
        Button("Schedule for 5 seconds") { /* scheduled notification */ }

        Button("Delete all data") {
            confirmationModalDialogData = ConfirmationData(
                title: "Delete all data?",
                message: "This will permanently delete all data.",
                action: { viewModel.deleteAllData() }
            )
        }

        Button(action: { showJourneyPickerForRandomData = true }) {
            HStack {
                Image(systemName: "dice.fill").foregroundColor(.purple)
                Text(L("Generate random data"))
            }
        }

        Button(action: { showUserSettingsTableContent = true }) {
            HStack {
                Image(systemName: "tablecells").foregroundColor(.blue)
                Text("View user_settings table")
            }
        }

        Button(action: { showResetMigrationConfirmation = true }) {
            HStack {
                Image(systemName: "arrow.triangle.2.circlepath").foregroundColor(.orange)
                Text(L("Reset migration"))
            }
        }
    }
}
```

---

## Required Services

### 1. DatabaseManager

Central database access point. Singleton pattern.

```swift
class DatabaseManager {
    static let shared = DatabaseManager()

    var userSettingsRepository: UserSettingsRepository?
    // ... other repositories

    private var db: Connection?

    private init() {
        // Initialize SQLite connection
        // Create repositories
        // Run migrations
    }

    func deleteAllData() {
        // Delete all records from all tables
    }

    func getDatabaseSchemaVersion() -> Int {
        return latestVersion
    }
}
```

### 2. EnvironmentService

Provides app configuration from Info.plist.

```swift
class EnvironmentService: ObservableObject {
    static let shared = EnvironmentService()

    func getAppVisibleVersion() -> String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }

    func getAppStoreId() -> String? {
        Bundle.main.object(forInfoDictionaryKey: "AppStoreId") as? String
    }

    func getDeveloperName() -> String {
        Bundle.main.object(forInfoDictionaryKey: "DeveloperName") as? String ?? "-"
    }

    func getDeveloperTelegramLink() -> String {
        // Return telegram link from Info.plist
    }

    func getAppStoreAppLink() -> String {
        "https://apps.apple.com/app/id\(getAppStoreId()!)"
    }

    func isDevelopmentMode() -> Bool {
        getBuildEnvironment() == "dev"
    }

    func getOsVersion() -> String {
        UIDevice.current.systemVersion
    }
}
```

**Required Info.plist keys:**
- `AppStoreId`
- `DeveloperName`
- `DeveloperTelegramLink`
- `BuildEnvironment` ("dev" or "prod")
- `GithubRepoUrl`

### 3. DeveloperModeManager

Manages hidden developer mode (activated by tapping version 15 times).

```swift
class DeveloperModeManager: ObservableObject {
    static let shared = DeveloperModeManager()

    @Published private(set) var isDeveloperModeEnabled: Bool = false
    @Published var tapCount: Int = 0
    @Published var shouldShowActivationAlert: Bool = false

    private let requiredTaps = 15

    func handleVersionTap() {
        tapCount += 1
        if tapCount >= requiredTaps && !isDeveloperModeEnabled {
            enableDeveloperMode()
            tapCount = 0
        }
    }

    func enableDeveloperMode() {
        isDeveloperModeEnabled = true
        shouldShowActivationAlert = true
    }

    func disableDeveloperMode() {
        isDeveloperModeEnabled = false
        tapCount = 0
    }

    func dismissAlert() {
        shouldShowActivationAlert = false
    }
}
```

### 4. NotificationManager

Handles local notifications.

```swift
class NotificationManager: ObservableObject {
    static let shared = NotificationManager()

    func getAuthorizationStatus(completion: @escaping (UNAuthorizationStatus) -> Void)
    func requestPermission()
    func checkAndRequestPermission(completion: @escaping () -> Void,
                                   onDeniedNotificationPermission: @escaping () -> Void)
    func cancelNotification(_ id: String)
    func sendNotification(title: String, body: String) -> String
    func scheduleNotification(title: String, body: String, afterSeconds: Int32) -> String
    func scheduleNotification(title: String, body: String, on date: Date) -> String
}
```

### 5. NetworkMonitor

Monitors network connectivity using `NWPathMonitor`.

```swift
@MainActor
final class NetworkMonitor: ObservableObject {
    static let shared = NetworkMonitor()

    @Published private(set) var isConnected: Bool = true
    @Published private(set) var connectionType: ConnectionType = .unknown

    enum ConnectionType {
        case wifi, cellular, wiredEthernet, unknown
    }

    func checkConnectivity() -> Bool { isConnected }
    func requireNetwork() throws { /* throws if not connected */ }
}
```

### 6. ColorSchemeManager

Manages app color scheme preference.

```swift
final class ColorSchemeManager: ObservableObject {
    static let shared = ColorSchemeManager()

    @Published var currentScheme: AppColorScheme

    func setScheme(_ scheme: AppColorScheme) throws

    var preferredColorScheme: ColorScheme? {
        switch currentScheme {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}
```

### 7. LocalizationManager

Manages app language with global `L()` function.

```swift
final class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()

    @Published var currentLanguage: AppLanguage

    func setLanguage(_ language: AppLanguage) throws
    func localizedString(forKey key: String) -> String
}

// Global helper
func L(_ key: String) -> String {
    LocalizationManager.shared.localizedString(forKey: key)
}
```

### 8. AppVersionChecker

Checks App Store for newer version.

```swift
protocol AppVersionCheckerProtocol {
    func checkAppStoreVersion() async -> Bool?
}

class AppVersionChecker: AppVersionCheckerProtocol {
    private let environment: EnvironmentService

    func checkAppStoreVersion() async -> Bool? {
        // Fetch from iTunes lookup API
        // Compare with current version
        // Return true if update available, false if current, nil on error
    }
}
```

### 9. BackupService

Handles data export/import and iCloud backup.

```swift
class BackupService {
    static let shared = BackupService()

    func isiCloudAvailable() -> Bool
    func exportData() async throws -> URL
    func importData(from url: URL) async throws
    func parseExportFile(_ url: URL) async throws -> ExportData
    func validateExportData(_ data: ExportData) throws
    func createiCloudBackup() async throws -> BackupInfo
    func listiCloudBackups() async throws -> [BackupInfo]
    func restoreFromiCloudBackup(_ info: BackupInfo) async throws
    func deleteiCloudBackup(_ info: BackupInfo) async throws
    func deleteAlliCloudBackups() async throws
}
```

### 10. BackgroundTaskManager

Manages automatic background backups.

```swift
class BackgroundTaskManager {
    static let shared = BackgroundTaskManager()

    var isAutomaticBackupEnabled: Bool
    var lastAutomaticBackupDate: Date?

    func registerBackgroundTasks()
    func scheduleNextBackup()
    func retryIfNeeded() async
}
```

---

## Required Models

### AppLanguage

```swift
enum AppLanguage: String, CaseIterable, Codable {
    case en = "en"
    case de = "de"
    case ru = "ru"
    // Add other languages as needed

    var displayName: String {
        switch self {
        case .en: return "🇬🇧 English"
        case .de: return "🇩🇪 Deutsch"
        case .ru: return "🇷🇺 Русский"
        }
    }
}
```

### AppColorScheme

```swift
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

---

## Helper Components

### ConfirmationData

For showing confirmation dialogs.

```swift
class ConfirmationData: ObservableObject {
    static let empty = ConfirmationData(title: "", message: "", action: {}, showDialog: false)

    @Published var title: String
    @Published var message: String
    @Published var confirmButtonTitle: String = "Confirm"
    @Published var cancelButtonTitle: String = "Cancel"
    @Published var action: () -> Void
    @Published var showDialog = true

    init(title: String, message: String, action: @escaping () -> Void, ...)
}
```

### ShareSheet

UIKit wrapper for sharing files.

```swift
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
```

### AboutAppSubView

Modal showing app information.

```swift
struct AboutAppSubView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading) {
                    Text(L("App description"))
                    // GitHub link
                    // Version info
                    // Developer info
                }
            }
            .navigationTitle(L("App Name"))
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(L("Close")) { dismiss() }
                }
            }
        }
    }
}
```

---

## UserSettingsViewModel

Main ViewModel handling all settings logic.

```swift
@MainActor
class UserSettingsViewModel: ObservableObject {
    static let onboardingCompletedKey = "isOnboardingComplete"

    // Published properties
    @Published var defaultCurrency: Currency
    @Published var selectedLanguage: AppLanguage
    @Published var selectedColorScheme: AppColorScheme
    @Published var isExporting: Bool = false
    @Published var isImporting: Bool = false
    @Published var exportError: String?
    @Published var importError: String?
    @Published var showImportConfirmation: Bool = false
    @Published var isBackingUp: Bool = false
    @Published var lastBackupDate: Date?
    @Published var isAutomaticBackupEnabled: Bool = false

    // Dependencies
    private let environment: EnvironmentService
    private let db: DatabaseManager
    private let developerMode: DeveloperModeManager
    private let backupService: BackupService
    private let userSettingsRepository: UserSettingsRepository?

    init(
        environment: EnvironmentService = .shared,
        db: DatabaseManager = .shared,
        developerMode: DeveloperModeManager = .shared,
        backupService: BackupService = .shared
    ) {
        // Initialize from repositories
    }

    // Methods
    func handleVersionTap()  // Delegates to DeveloperModeManager
    func openWebURL(_ url: URL)
    func saveDefaultCurrency(_ currency: Currency)
    func saveLanguage(_ language: AppLanguage)
    func saveColorScheme(_ scheme: AppColorScheme)
    func isSpecialDeveloperModeEnabled() -> Bool
    func isDevelopmentMode() -> Bool
    func deleteAllData()
    func exportData() async -> URL?
    func prepareImport(from fileURL: URL) async
    func confirmImport() async
    func cancelImport()
    func createiCloudBackup() async
    func loadiCloudBackups() async
    func restoreFromiCloudBackup(_ info: BackupInfo) async
    func deleteiCloudBackup(_ info: BackupInfo) async
    func isiCloudAvailable() -> Bool
    func toggleAutomaticBackup(_ enabled: Bool)
    func generateRandomDataForJourney(_ journey: Journey)  // Dev only
}
```

---

## UserSettingsRepository

Database repository for key-value settings.

```swift
class UserSettingsRepository {
    private let table: Table
    private let id = Expression<Int64>("id")
    private let keyColumn = Expression<String>("key")
    private let valueColumn = Expression<String>("value")

    func createTable()
    func fetchValue(for key: String) -> String?
    func upsertValue(key: String, value: String) -> Bool

    // Convenience methods
    func fetchCurrency() -> Currency
    func upsertCurrency(_ currencyValue: String) -> Bool
    func fetchLanguage() -> AppLanguage
    func upsertLanguage(_ languageValue: String) -> Bool
    func fetchColorScheme() -> AppColorScheme
    func upsertColorScheme(_ scheme: AppColorScheme) -> Bool
    func fetchOrGenerateUserId() -> String
    func fetchAll() -> [(id: Int64, key: String, value: String)]
}
```

---

## View State Properties

The view uses these `@State` properties:

```swift
@State var showAppUpdateButton: Bool = false
@State private var showEditCurrencyModal: Bool = false
@State private var isNotificationsEnabled: Bool = false
@State private var showingAppAboutModal = false
@State private var confirmationModalDialogData = ConfirmationData.empty
@State private var showDeveloperModeAlert = false
@State private var showExportShareSheet = false
@State private var exportFileURL: URL?
@State private var showImportFilePicker = false
@State private var showJourneyPickerForRandomData = false  // Dev
@State private var showUserSettingsTableContent = false     // Dev
@State private var showResetMigrationConfirmation = false   // Dev
```

---

## Implementation Order

1. **Create models**: `AppLanguage`, `AppColorScheme`
2. **Create DatabaseManager** with SQLite setup
3. **Create UserSettingsRepository**
4. **Create services**:
   - EnvironmentService
   - LocalizationManager (with `L()` function)
   - ColorSchemeManager
   - NotificationManager
   - NetworkMonitor
   - DeveloperModeManager
   - BackupService (can be simplified initially)
5. **Create helper components**: ConfirmationData, ShareSheet
6. **Create UserSettingsViewModel**
7. **Create AboutAppSubView**
8. **Create UserSettingsView** with all sections

---

## Key Patterns

### Analytics Tracking

Every user interaction should be tracked:

```swift
analytics.trackEvent("button_name_clicked", properties: [
    "screen": "user_settings_screen",
    "button_name": "specific_button"
])
```

### Screen Tracking

On view appear:

```swift
.onAppear {
    analytics.trackScreen("user_settings_screen")
    refreshData()
}
```

### Refresh Pattern

Pull-to-refresh support:

```swift
.refreshable {
    refreshData()
}
```

### Modal Sheets

Use `.sheet(isPresented:)` for modals:

```swift
.sheet(isPresented: $showEditCurrencyModal) {
    EditDefaultCurrencyView(...)
}
.sheet(isPresented: $showingAppAboutModal) {
    AboutAppSubView()
}
```

### File Import

Use `.fileImporter` for importing files:

```swift
.fileImporter(
    isPresented: $showImportFilePicker,
    allowedContentTypes: [.json],
    allowsMultipleSelection: false
) { result in
    // Handle result
}
```

### Confirmation Alerts

Use `.alert` with ConfirmationData:

```swift
.alert(confirmationModalDialogData.title, isPresented: $confirmationModalDialogData.showDialog) {
    Button(confirmationModalDialogData.cancelButtonTitle, role: .cancel) { }
    Button(confirmationModalDialogData.confirmButtonTitle, role: .destructive) {
        confirmationModalDialogData.action()
    }
} message: {
    Text(confirmationModalDialogData.message)
}
```

---

## StoreKit Integration

For "Rate the app" functionality:

```swift
import StoreKit

struct UserSettingsView: View {
    @Environment(\.requestReview) var requestReview

    // In button action:
    Button { requestReview() } label: {
        // ...
    }
}
```

---

## Opening System Settings

```swift
private func openSettings() {
    if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
        UIApplication.shared.open(settingsUrl)
    }
}
```
