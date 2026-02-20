import Foundation
import SwiftUI
import UserNotifications
import os

@MainActor
@Observable
final class UserSettingsViewModel {
    var defaultCurrency: Currency
    var selectedLanguage: AppLanguage
    var selectedColorScheme: AppColorScheme

    // Backup state
    var isExporting = false
    var isImporting = false
    var isLoadingBackups = false
    var isCreatingiCloudBackup = false
    var iCloudBackups: [BackupInfo] = []
    var backupError: String?
    var exportFileURL: URL?
    var isAutomaticBackupEnabled = false
    var lastAutomaticBackupDate: Date?
    var lastiCloudBackupDate: Date?

    // Developer mode
    var projects: [Project] = []

    private let db: DatabaseManager
    private let developerMode: DeveloperModeManager
    private let userSettingsRepository: UserSettingsRepository?
    private let backupService: BackupService
    private let backgroundTaskManager: BackgroundTaskManager
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "-",
        category: "UserSettingsViewModel"
    )

    var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "-"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "-"
        return "\(version) (\(build))"
    }

    var developerName: String {
        Bundle.main.object(forInfoDictionaryKey: "DeveloperName") as? String ?? ""
    }

    var telegramLink: String {
        Bundle.main.object(forInfoDictionaryKey: "DeveloperTelegramLink") as? String ?? ""
    }

    var isiCloudAvailable: Bool {
        backupService.isiCloudAvailable()
    }

    var isDevModeEnabled: Bool {
        developerMode.isDeveloperModeEnabled
    }

    var isDevelopmentMode: Bool {
        let buildEnv = Bundle.main.object(forInfoDictionaryKey: "BuildEnvironment") as? String ?? ""
        return buildEnv == "dev" || developerMode.isDeveloperModeEnabled
    }

    var databaseSchemaVersion: Int {
        db.getDatabaseSchemaVersion()
    }

    init(
        db: DatabaseManager = .shared,
        backupService: BackupService = .shared,
        developerMode: DeveloperModeManager = .shared,
        backgroundTaskManager: BackgroundTaskManager = .shared
    ) {
        self.db = db
        self.developerMode = developerMode
        self.userSettingsRepository = db.userSettingsRepository
        self.backupService = backupService
        self.backgroundTaskManager = backgroundTaskManager
        self.defaultCurrency = userSettingsRepository?.fetchCurrency() ?? .usd
        self.selectedLanguage = userSettingsRepository?.fetchLanguage() ?? .en
        self.selectedColorScheme = userSettingsRepository?.fetchColorScheme() ?? .system
        self.isAutomaticBackupEnabled = backgroundTaskManager.isAutomaticBackupEnabled
        self.lastAutomaticBackupDate = backgroundTaskManager.lastAutomaticBackupDate
    }

    func saveDefaultCurrency(_ currency: Currency) {
        defaultCurrency = currency
        userSettingsRepository?.upsertCurrency(currency.rawValue)
    }

    func saveLanguage(_ language: AppLanguage) {
        selectedLanguage = language
        LocalizationManager.shared.setLanguage(language)
    }

    func saveColorScheme(_ scheme: AppColorScheme) {
        selectedColorScheme = scheme
        userSettingsRepository?.upsertColorScheme(scheme)

        NotificationCenter.default.post(
            name: .appColorSchemeDidChange,
            object: nil,
            userInfo: ["colorScheme": scheme.rawValue]
        )
    }

    // MARK: - Export

    func exportData() async {
        isExporting = true
        do {
            let fileURL = try await backupService.exportData()
            exportFileURL = fileURL
        } catch {
            logger.error("Export failed: \(error.localizedDescription)")
            backupError = error.localizedDescription
        }
        isExporting = false
    }

    // MARK: - Import

    func importData(from url: URL) async {
        isImporting = true
        do {
            try await backupService.importData(from: url)
            reloadSettings()
        } catch {
            logger.error("Import failed: \(error.localizedDescription)")
            backupError = error.localizedDescription
        }
        isImporting = false
    }

    // MARK: - iCloud Backup

    func createiCloudBackup() async {
        isCreatingiCloudBackup = true
        do {
            let backupInfo = try await backupService.createiCloudBackup()
            lastiCloudBackupDate = backupInfo.createdAt
            await loadiCloudBackups()
        } catch {
            logger.error("iCloud backup failed: \(error.localizedDescription)")
            backupError = error.localizedDescription
        }
        isCreatingiCloudBackup = false
    }

    func loadiCloudBackups() async {
        isLoadingBackups = true
        do {
            iCloudBackups = try await backupService.listiCloudBackups()
            lastiCloudBackupDate = iCloudBackups.first?.createdAt
        } catch {
            logger.error("Failed to load iCloud backups: \(error.localizedDescription)")
            backupError = error.localizedDescription
        }
        isLoadingBackups = false
    }

    func restoreFromiCloudBackup(_ backup: BackupInfo) async {
        isImporting = true
        do {
            try await backupService.restoreFromiCloudBackup(backup)
            reloadSettings()
        } catch {
            logger.error("iCloud restore failed: \(error.localizedDescription)")
            backupError = error.localizedDescription
        }
        isImporting = false
    }

    func deleteiCloudBackup(_ backup: BackupInfo) async {
        do {
            try await backupService.deleteiCloudBackup(backup)
            await loadiCloudBackups()
        } catch {
            logger.error("Delete iCloud backup failed: \(error.localizedDescription)")
            backupError = error.localizedDescription
        }
    }

    func deleteAlliCloudBackups() async {
        do {
            try await backupService.deleteAlliCloudBackups()
            iCloudBackups = []
            lastiCloudBackupDate = nil
        } catch {
            logger.error("Delete all iCloud backups failed: \(error.localizedDescription)")
            backupError = error.localizedDescription
        }
    }

    // MARK: - Automatic Backup

    func toggleAutomaticBackup(_ enabled: Bool) {
        isAutomaticBackupEnabled = enabled
        backgroundTaskManager.isAutomaticBackupEnabled = enabled
    }

    func refreshAutomaticBackupState() {
        isAutomaticBackupEnabled = backgroundTaskManager.isAutomaticBackupEnabled
        lastAutomaticBackupDate = backgroundTaskManager.lastAutomaticBackupDate
    }

    // MARK: - Developer Mode

    func handleVersionTap() {
        developerMode.handleVersionTap()
    }

    func loadProjects() {
        projects = db.projectRepository?.fetchAll() ?? []
    }

    func generateRandomData(for project: Project) {
        guard isDevelopmentMode else {
            logger.warning("Attempt to generate random data in non-development mode. Operation aborted.")
            return
        }

        logger.info("Generating random data for project: \(project.name)")
        let generator = RandomDataGenerator(db: db)
        generator.generateRandomData(for: project)
        logger.info("Random data generation completed for project: \(project.name)")
    }

    func deleteAllData() {
        guard isDevelopmentMode else {
            logger.warning("Attempt to delete all data in non-development mode. Operation aborted.")
            return
        }

        db.deleteAllData()
        logger.info("All data deleted via developer mode")
    }

    // MARK: - Notifications

    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if let error {
                self.logger.error("Notification permission error: \(error.localizedDescription)")
            } else {
                self.logger.info("Notification permission granted: \(granted)")
            }
        }
    }

    func sendTestNotification() {
        let content = UNMutableNotificationContent()
        content.title = "CreativityHub"
        content.body = "Test notification"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                self.logger.error("Failed to send test notification: \(error.localizedDescription)")
            }
        }
    }

    func scheduleTestNotification(afterSeconds seconds: TimeInterval) {
        let content = UNMutableNotificationContent()
        content.title = "CreativityHub"
        content.body = "Scheduled test notification (\(Int(seconds))s)"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: false)
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                self.logger.error("Failed to schedule test notification: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Migration Reset

    func resetDatabaseMigrations() {
        guard isDevelopmentMode else {
            logger.warning("Attempt to reset migrations in non-development mode. Operation aborted.")
            return
        }

        db.migrationRepository?.resetMigrations()
        logger.info("Database migrations reset via developer mode")
    }

    // MARK: - Private

    private func reloadSettings() {
        defaultCurrency = userSettingsRepository?.fetchCurrency() ?? .usd
        selectedLanguage = userSettingsRepository?.fetchLanguage() ?? .en
        selectedColorScheme = userSettingsRepository?.fetchColorScheme() ?? .system
    }
}
