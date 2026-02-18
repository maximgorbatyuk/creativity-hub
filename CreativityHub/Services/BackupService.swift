import Foundation
import os

@MainActor
final class BackupService {
    static let shared = BackupService()

    // MARK: - Constants

    private let maxSafetyBackups = 3
    private let maxiCloudBackups = 5
    private let maxBackupAgeInDays = 30

    // MARK: - File Paths

    private var safetyBackupDirectory: URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsPath
            .appendingPathComponent("creativityhub", isDirectory: true)
            .appendingPathComponent("safety_backups", isDirectory: true)
    }

    private var iCloudBackupDirectory: URL? {
        guard isiCloudAvailable() else {
            logger.warning("iCloud not available - ubiquity identity token is nil")
            return nil
        }

        var bundleIdentifier = Bundle.main.bundleIdentifier ?? "dev.mgorbatyuk.CreativityHub"
        if bundleIdentifier.contains("Debug") {
            bundleIdentifier = bundleIdentifier.replacingOccurrences(of: "Debug", with: "")
        }

        let containerIdentifier = "iCloud.\(bundleIdentifier)"

        guard let containerURL = FileManager.default.url(
            forUbiquityContainerIdentifier: containerIdentifier
        ) ?? FileManager.default.url(forUbiquityContainerIdentifier: nil) else {
            logger.warning("Failed to get iCloud container URL for identifier: \(containerIdentifier)")
            return nil
        }

        return containerURL
            .appendingPathComponent("Documents", isDirectory: true)
            .appendingPathComponent("creativityhub", isDirectory: true)
            .appendingPathComponent("backups", isDirectory: true)
    }

    // MARK: - Dependencies

    private let currentSchemaVersion: Int
    private let settingsRepository: UserSettingsRepository?
    private let projectRepository: ProjectRepository?
    private let checklistRepository: ChecklistRepository?
    private let checklistItemRepository: ChecklistItemRepository?
    private let ideaRepository: IdeaRepository?
    private let tagRepository: TagRepository?
    private let expenseRepository: ExpenseRepository?
    private let expenseCategoryRepository: ExpenseCategoryRepository?
    private let noteRepository: NoteRepository?
    private let documentRepository: DocumentRepository?
    private let reminderRepository: ReminderRepository?
    private let databaseManager: DatabaseManager
    private let logger: Logger

    init(databaseManager: DatabaseManager = .shared) {
        self.databaseManager = databaseManager
        self.currentSchemaVersion = databaseManager.getDatabaseSchemaVersion()
        self.settingsRepository = databaseManager.userSettingsRepository
        self.projectRepository = databaseManager.projectRepository
        self.checklistRepository = databaseManager.checklistRepository
        self.checklistItemRepository = databaseManager.checklistItemRepository
        self.ideaRepository = databaseManager.ideaRepository
        self.tagRepository = databaseManager.tagRepository
        self.expenseRepository = databaseManager.expenseRepository
        self.expenseCategoryRepository = databaseManager.expenseCategoryRepository
        self.noteRepository = databaseManager.noteRepository
        self.documentRepository = databaseManager.documentRepository
        self.reminderRepository = databaseManager.reminderRepository
        self.logger = Logger(
            subsystem: Bundle.main.bundleIdentifier ?? "-",
            category: "BackupService"
        )
    }

    // MARK: - Export

    func exportData() async throws -> URL {
        let exportData = createExportData()
        let fileURL = try saveExportToTemporaryFile(exportData)
        return fileURL
    }

    private func createExportData() -> ExportData {
        let settings = fetchUserSettings()

        let metadata = ExportMetadata(
            appVersion: getAppVersion(),
            deviceName: getDeviceName(),
            databaseSchemaVersion: currentSchemaVersion
        )

        let ideaTagTuples = tagRepository?.fetchAllIdeaTagLinks() ?? []
        let ideaTagLinks = ideaTagTuples.map { IdeaTagLink(ideaId: $0.ideaId, tagId: $0.tagId) }

        return ExportData(
            metadata: metadata,
            userSettings: settings,
            projects: projectRepository?.fetchAll(),
            checklists: checklistRepository?.fetchAll(),
            checklistItems: checklistItemRepository?.fetchAll(),
            ideas: ideaRepository?.fetchAll(),
            tags: tagRepository?.fetchAll(),
            ideaTagLinks: ideaTagLinks.isEmpty ? nil : ideaTagLinks,
            expenses: expenseRepository?.fetchAll(),
            expenseCategories: expenseCategoryRepository?.fetchAll(),
            notes: noteRepository?.fetchAll(),
            documents: documentRepository?.fetchAll(),
            reminders: reminderRepository?.fetchAll()
        )
    }

    private func saveExportToTemporaryFile(_ exportData: ExportData) throws -> URL {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        let jsonData = try encoder.encode(exportData)

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let timestamp = dateFormatter.string(from: Date())
        let filename = "creativityhub_export_\(timestamp).json"

        let tempDirectory = FileManager.default.temporaryDirectory
        let fileURL = tempDirectory.appendingPathComponent(filename)

        try jsonData.write(to: fileURL)

        var resourceValues = URLResourceValues()
        resourceValues.isExcludedFromBackup = true
        var mutableURL = fileURL
        try mutableURL.setResourceValues(resourceValues)

        return fileURL
    }

    // MARK: - Import

    func importData(from fileURL: URL) async throws {
        let exportData = try parseExportFile(fileURL)
        try validateExportData(exportData)

        let safetyBackupURL = try createSafetyBackup()

        do {
            wipeAllData()
            importExportData(exportData)
            cleanupOldSafetyBackups()
        } catch {
            logger.error("Import failed: \(error.localizedDescription). Restoring from safety backup.")
            try restoreFromSafetyBackup(safetyBackupURL)
            throw error
        }
    }

    func parseExportFile(_ fileURL: URL) throws -> ExportData {
        let data = try Data(contentsOf: fileURL)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        do {
            return try decoder.decode(ExportData.self, from: data)
        } catch {
            logger.error("Failed to parse export file: \(error)")
            throw ExportValidationError.invalidJSON
        }
    }

    func validateExportData(_ exportData: ExportData) throws {
        let metadata = exportData.metadata

        if metadata.databaseSchemaVersion > currentSchemaVersion {
            throw ExportValidationError.newerSchemaVersion(
                current: currentSchemaVersion,
                file: metadata.databaseSchemaVersion
            )
        }
    }

    private func createSafetyBackup() throws -> URL {
        try FileManager.default.createDirectory(
            at: safetyBackupDirectory,
            withIntermediateDirectories: true
        )

        let exportData = createExportData()

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let timestamp = dateFormatter.string(from: Date())
        let filename = "safety_backup_before_import_\(timestamp).json"

        let fileURL = safetyBackupDirectory.appendingPathComponent(filename)

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        let jsonData = try encoder.encode(exportData)
        try jsonData.write(to: fileURL)

        logger.info("Safety backup created at: \(fileURL.path)")

        return fileURL
    }

    private func restoreFromSafetyBackup(_ backupURL: URL) throws {
        logger.info("Restoring from safety backup: \(backupURL.path)")

        let exportData = try parseExportFile(backupURL)
        wipeAllData()
        importExportData(exportData)

        logger.info("Successfully restored from safety backup")
    }

    private func cleanupOldSafetyBackups() {
        do {
            let fileManager = FileManager.default
            let backupFiles = try fileManager.contentsOfDirectory(
                at: safetyBackupDirectory,
                includingPropertiesForKeys: [.creationDateKey],
                options: [.skipsHiddenFiles]
            )

            let sortedBackups = try backupFiles.sorted { url1, url2 in
                let date1 = try url1.resourceValues(forKeys: [.creationDateKey]).creationDate ?? Date.distantPast
                let date2 = try url2.resourceValues(forKeys: [.creationDateKey]).creationDate ?? Date.distantPast
                return date1 > date2
            }

            let backupsToDelete = sortedBackups.dropFirst(maxSafetyBackups)
            for backup in backupsToDelete {
                try fileManager.removeItem(at: backup)
                logger.info("Deleted old safety backup: \(backup.lastPathComponent)")
            }
        } catch {
            logger.error("Failed to cleanup old safety backups: \(error)")
        }
    }

    private func wipeAllData() {
        databaseManager.deleteAllData()
        logger.info("All data wiped from database")
    }

    private func importExportData(_ exportData: ExportData) {
        // Import user settings
        if let currency = Currency.allCases.first(where: { $0.rawValue == exportData.userSettings.preferredCurrency }) {
            _ = settingsRepository?.upsertCurrency(currency.rawValue)
        }
        if let language = AppLanguage.allCases.first(where: { $0.rawValue == exportData.userSettings.preferredLanguage }) {
            _ = settingsRepository?.upsertLanguage(language)
        }
        if let colorScheme = AppColorScheme.allCases.first(where: { $0.rawValue == exportData.userSettings.preferredColorScheme }) {
            _ = settingsRepository?.upsertColorScheme(colorScheme)
        }

        // Import projects first (parent entities)
        if let projects = exportData.projects {
            for project in projects {
                _ = projectRepository?.insert(project)
            }
            logger.info("Imported \(projects.count) projects")
        }

        // Import checklists (before items)
        if let checklists = exportData.checklists {
            for checklist in checklists {
                _ = checklistRepository?.insert(checklist)
            }
            logger.info("Imported \(checklists.count) checklists")
        }

        // Import checklist items
        if let checklistItems = exportData.checklistItems {
            for item in checklistItems {
                _ = checklistItemRepository?.insert(item)
            }
            logger.info("Imported \(checklistItems.count) checklist items")
        }

        // Import tags (before idea-tag links)
        if let tags = exportData.tags {
            for tag in tags {
                _ = tagRepository?.insert(tag)
            }
            logger.info("Imported \(tags.count) tags")
        }

        // Import ideas
        if let ideas = exportData.ideas {
            for idea in ideas {
                _ = ideaRepository?.insert(idea)
            }
            logger.info("Imported \(ideas.count) ideas")
        }

        // Import idea-tag links
        if let ideaTagLinks = exportData.ideaTagLinks {
            for link in ideaTagLinks {
                _ = tagRepository?.linkTagToIdea(tagId: link.tagId, ideaId: link.ideaId)
            }
            logger.info("Imported \(ideaTagLinks.count) idea-tag links")
        }

        // Import expense categories (before expenses)
        if let categories = exportData.expenseCategories {
            for category in categories {
                _ = expenseCategoryRepository?.insert(category)
            }
            logger.info("Imported \(categories.count) expense categories")
        }

        // Import expenses
        if let expenses = exportData.expenses {
            for expense in expenses {
                _ = expenseRepository?.insert(expense)
            }
            logger.info("Imported \(expenses.count) expenses")
        }

        // Import notes
        if let notes = exportData.notes {
            for note in notes {
                _ = noteRepository?.insert(note)
            }
            logger.info("Imported \(notes.count) notes")
        }

        // Import documents (metadata only)
        if let documents = exportData.documents {
            for document in documents {
                _ = documentRepository?.insert(document)
            }
            logger.info("Imported \(documents.count) documents")
        }

        // Import reminders
        if let reminders = exportData.reminders {
            for reminder in reminders {
                _ = reminderRepository?.insert(reminder)
            }
            logger.info("Imported \(reminders.count) reminders")
        }

        logger.info("Successfully imported all data")
    }

    // MARK: - Helper Methods

    private func fetchUserSettings() -> ExportUserSettings {
        let currency = settingsRepository?.fetchCurrency() ?? .usd
        let language = settingsRepository?.fetchLanguage() ?? .en
        let colorScheme = settingsRepository?.fetchColorScheme() ?? .system

        return ExportUserSettings(currency: currency, language: language, colorScheme: colorScheme)
    }

    private func getAppVersion() -> String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
        return "\(version) (\(build))"
    }

    private func getDeviceName() -> String {
        ProcessInfo.processInfo.hostName
    }

    // MARK: - iCloud Backup

    func isiCloudAvailable() -> Bool {
        FileManager.default.ubiquityIdentityToken != nil
    }

    private func checkiCloudStatus() throws {
        guard isiCloudAvailable() else {
            throw BackupError.iCloudNotAvailable
        }

        guard iCloudBackupDirectory != nil else {
            throw BackupError.iCloudNotAvailable
        }
    }

    func createiCloudBackup() async throws -> BackupInfo {
        try checkiCloudStatus()

        guard let backupDirectory = iCloudBackupDirectory else {
            throw BackupError.iCloudNotAvailable
        }

        let exportData = createExportData()

        try createiCloudDirectoryIfNeeded()

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let timestamp = dateFormatter.string(from: Date())
        let filename = "creativityhub_backup_\(timestamp).json"

        let fileURL = backupDirectory.appendingPathComponent(filename)

        let coordinator = NSFileCoordinator()
        var coordinatorError: NSError?

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            var didResume = false

            coordinator.coordinate(
                writingItemAt: fileURL,
                options: .forReplacing,
                error: &coordinatorError
            ) { url in
                do {
                    let encoder = JSONEncoder()
                    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
                    encoder.dateEncodingStrategy = .iso8601

                    let jsonData = try encoder.encode(exportData)
                    try jsonData.write(to: url)

                    self.logger.info("iCloud backup created: \(filename)")
                    if !didResume {
                        didResume = true
                        continuation.resume()
                    }
                } catch {
                    self.logger.error("Failed to write iCloud backup: \(error)")
                    if !didResume {
                        didResume = true
                        continuation.resume(throwing: error)
                    }
                }
            }

            if let error = coordinatorError, !didResume {
                didResume = true
                continuation.resume(throwing: error)
            }
        }

        try await cleanupOldiCloudBackups()

        let backupInfo = try getBackupInfo(from: fileURL)
        return backupInfo
    }

    func listiCloudBackups() async throws -> [BackupInfo] {
        try checkiCloudStatus()

        guard let backupDirectory = iCloudBackupDirectory else {
            throw BackupError.iCloudNotAvailable
        }

        return try await withCheckedThrowingContinuation { continuation in
            let coordinator = NSFileCoordinator()
            var coordinatorError: NSError?
            var didResume = false

            coordinator.coordinate(
                readingItemAt: backupDirectory,
                options: [.withoutChanges],
                error: &coordinatorError
            ) { url in
                do {
                    let fileManager = FileManager.default

                    if !fileManager.fileExists(atPath: url.path) {
                        try fileManager.createDirectory(
                            at: url,
                            withIntermediateDirectories: true
                        )
                        if !didResume {
                            didResume = true
                            continuation.resume(returning: [])
                        }
                        return
                    }

                    let files = try fileManager.contentsOfDirectory(
                        at: url,
                        includingPropertiesForKeys: [.creationDateKey, .fileSizeKey],
                        options: [.skipsHiddenFiles]
                    )

                    let jsonFiles = files.filter { $0.pathExtension == "json" }

                    var backups: [BackupInfo] = []
                    for fileURL in jsonFiles {
                        if let info = try? self.getBackupInfo(from: fileURL) {
                            backups.append(info)
                        }
                    }

                    backups.sort { $0.createdAt > $1.createdAt }

                    if !didResume {
                        didResume = true
                        continuation.resume(returning: backups)
                    }
                } catch {
                    self.logger.error("Failed to list iCloud backups: \(error)")
                    if !didResume {
                        didResume = true
                        continuation.resume(throwing: error)
                    }
                }
            }

            if let error = coordinatorError, !didResume {
                didResume = true
                continuation.resume(throwing: error)
            }
        }
    }

    func restoreFromiCloudBackup(_ backupInfo: BackupInfo) async throws {
        try checkiCloudStatus()

        let safetyBackupURL = try createSafetyBackup()

        do {
            let exportData = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<ExportData, Error>) in
                let coordinator = NSFileCoordinator()
                var coordinatorError: NSError?
                var didResume = false

                coordinator.coordinate(
                    readingItemAt: backupInfo.fileURL,
                    options: [.withoutChanges],
                    error: &coordinatorError
                ) { url in
                    do {
                        let data = try Data(contentsOf: url)

                        let decoder = JSONDecoder()
                        decoder.dateDecodingStrategy = .iso8601

                        let exportData = try decoder.decode(ExportData.self, from: data)
                        if !didResume {
                            didResume = true
                            continuation.resume(returning: exportData)
                        }
                    } catch {
                        self.logger.error("Failed to read iCloud backup: \(error)")
                        if !didResume {
                            didResume = true
                            continuation.resume(throwing: error)
                        }
                    }
                }

                if let error = coordinatorError, !didResume {
                    didResume = true
                    continuation.resume(throwing: error)
                }
            }

            try validateExportData(exportData)
            wipeAllData()
            importExportData(exportData)

            logger.info("Successfully restored from iCloud backup: \(backupInfo.fileName)")
        } catch {
            logger.error("Restore from iCloud failed: \(error.localizedDescription). Restoring from safety backup.")
            try restoreFromSafetyBackup(safetyBackupURL)
            throw error
        }
    }

    func deleteiCloudBackup(_ backupInfo: BackupInfo) async throws {
        try checkiCloudStatus()

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            let coordinator = NSFileCoordinator()
            var coordinatorError: NSError?
            var didResume = false

            coordinator.coordinate(
                writingItemAt: backupInfo.fileURL,
                options: .forDeleting,
                error: &coordinatorError
            ) { url in
                do {
                    try FileManager.default.removeItem(at: url)
                    self.logger.info("Deleted iCloud backup: \(backupInfo.fileName)")
                    if !didResume {
                        didResume = true
                        continuation.resume()
                    }
                } catch {
                    self.logger.error("Failed to delete iCloud backup: \(error)")
                    if !didResume {
                        didResume = true
                        continuation.resume(throwing: error)
                    }
                }
            }

            if let error = coordinatorError, !didResume {
                didResume = true
                continuation.resume(throwing: error)
            }
        }
    }

    func deleteAlliCloudBackups() async throws {
        try checkiCloudStatus()

        let backups = try await listiCloudBackups()
        guard !backups.isEmpty else { return }

        for backup in backups {
            try await deleteiCloudBackup(backup)
        }

        logger.info("Deleted all iCloud backups: \(backups.count) files")
    }

    private func createiCloudDirectoryIfNeeded() throws {
        guard let backupDirectory = iCloudBackupDirectory else {
            throw BackupError.iCloudNotAvailable
        }

        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: backupDirectory.path) {
            try fileManager.createDirectory(
                at: backupDirectory,
                withIntermediateDirectories: true
            )
            logger.info("Created iCloud backup directory")
        }
    }

    private func cleanupOldiCloudBackups() async throws {
        guard iCloudBackupDirectory != nil else { return }

        let backups = try await listiCloudBackups()

        let now = Date()
        let maxAge = TimeInterval(maxBackupAgeInDays * 24 * 60 * 60)

        var backupsToDelete: [BackupInfo] = []

        let oldBackups = backups.filter { now.timeIntervalSince($0.createdAt) > maxAge }
        backupsToDelete.append(contentsOf: oldBackups)

        if backups.count > maxiCloudBackups {
            let excessBackups = backups.dropFirst(maxiCloudBackups)
            backupsToDelete.append(contentsOf: excessBackups)
        }

        let uniqueURLs = Set(backupsToDelete.map { $0.fileURL })

        for fileURL in uniqueURLs {
            if let backup = backups.first(where: { $0.fileURL == fileURL }) {
                try? await deleteiCloudBackup(backup)
            }
        }

        if !uniqueURLs.isEmpty {
            logger.info("Cleaned up \(uniqueURLs.count) old iCloud backup(s)")
        }
    }

    private func getBackupInfo(from fileURL: URL) throws -> BackupInfo {
        let attributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)

        let creationDate = attributes[.creationDate] as? Date ?? Date()
        let fileSize = attributes[.size] as? Int64 ?? 0

        let data = try Data(contentsOf: fileURL)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let exportData = try decoder.decode(ExportData.self, from: data)

        return BackupInfo(
            fileName: fileURL.lastPathComponent,
            fileURL: fileURL,
            createdAt: creationDate,
            fileSize: fileSize,
            deviceName: exportData.metadata.deviceName,
            appVersion: exportData.metadata.appVersion,
            schemaVersion: exportData.metadata.databaseSchemaVersion
        )
    }
}

// MARK: - Backup Models

struct BackupInfo: Identifiable, Hashable {
    let fileName: String
    let fileURL: URL
    let createdAt: Date
    let fileSize: Int64
    let deviceName: String
    let appVersion: String
    let schemaVersion: Int

    var id: String { fileURL.absoluteString }

    var formattedFileSize: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: fileSize)
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(fileURL)
    }

    static func == (lhs: BackupInfo, rhs: BackupInfo) -> Bool {
        lhs.fileURL == rhs.fileURL
    }
}

enum BackupError: LocalizedError {
    case iCloudNotAvailable
    case iCloudStorageFull

    var errorDescription: String? {
        switch self {
        case .iCloudNotAvailable:
            return L("backup.error.icloud_not_available")
        case .iCloudStorageFull:
            return L("backup.error.icloud_storage_full")
        }
    }
}
