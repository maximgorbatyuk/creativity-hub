import Foundation
import SQLite
import os

class DatabaseManager {
    static let shared = DatabaseManager()

    private var db: Connection?
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "-",
        category: "DatabaseManager"
    )

    private let latestVersion = 5

    // Repositories
    private(set) var migrationRepository: MigrationsRepository?
    private(set) var userSettingsRepository: UserSettingsRepository?
    private(set) var projectRepository: ProjectRepository?
    private(set) var checklistRepository: ChecklistRepository?
    private(set) var checklistItemRepository: ChecklistItemRepository?
    private(set) var ideaRepository: IdeaRepository?
    private(set) var tagRepository: TagRepository?
    private(set) var expenseRepository: ExpenseRepository?
    private(set) var expenseCategoryRepository: ExpenseCategoryRepository?
    private(set) var noteRepository: NoteRepository?
    private(set) var documentRepository: DocumentRepository?
    private(set) var reminderRepository: ReminderRepository?

    private init() {
        setupDatabase()
    }

    func getDatabaseSchemaVersion() -> Int {
        Int(migrationRepository?.getLatestMigrationVersion() ?? 0)
    }

    func deleteAllData() {
        reminderRepository?.deleteAll()
        documentRepository?.deleteAll()
        noteRepository?.deleteAll()
        expenseRepository?.deleteAll()
        expenseCategoryRepository?.deleteAll()
        checklistItemRepository?.deleteAll()
        checklistRepository?.deleteAll()
        ideaRepository?.deleteAll()
        tagRepository?.deleteAll()
        projectRepository?.deleteAll()
        logger.info("All data deleted from database")
    }

    func deleteProjectCascade(projectId: UUID) -> Bool {
        var isSuccess = true

        if let remindersDeleted = reminderRepository?.deleteByProjectId(projectId: projectId) {
            isSuccess = remindersDeleted && isSuccess
        }

        if let notesDeleted = noteRepository?.deleteByProjectId(projectId: projectId) {
            isSuccess = notesDeleted && isSuccess
        }

        if let expensesDeleted = expenseRepository?.deleteByProjectId(projectId: projectId) {
            isSuccess = expensesDeleted && isSuccess
        }

        if let categoriesDeleted = expenseCategoryRepository?.deleteByProjectId(projectId: projectId) {
            isSuccess = categoriesDeleted && isSuccess
        }

        if let documentsDeleted = documentRepository?.deleteByProjectId(projectId: projectId) {
            isSuccess = documentsDeleted && isSuccess
        }

        let checklists = checklistRepository?.fetchByProjectId(projectId: projectId) ?? []
        for checklist in checklists {
            if let itemsDeleted = checklistItemRepository?.deleteByChecklistId(checklistId: checklist.id) {
                isSuccess = itemsDeleted && isSuccess
            }
        }

        if let checklistsDeleted = checklistRepository?.deleteByProjectId(projectId: projectId) {
            isSuccess = checklistsDeleted && isSuccess
        }

        let ideas = ideaRepository?.fetchByProjectId(projectId: projectId) ?? []
        for idea in ideas {
            if let linksDeleted = tagRepository?.deleteLinksForIdea(ideaId: idea.id) {
                isSuccess = linksDeleted && isSuccess
            }
        }

        if let ideasDeleted = ideaRepository?.deleteByProjectId(projectId: projectId) {
            isSuccess = ideasDeleted && isSuccess
        }

        let projectDeleted = projectRepository?.delete(id: projectId) ?? false
        isSuccess = projectDeleted && isSuccess

        if isSuccess {
            logger.info("Deleted project and related data: \(projectId)")
        } else {
            logger.error("Failed to fully delete project and related data: \(projectId)")
        }

        return isSuccess
    }

    private func setupDatabase() {
        do {
            let dbURL = AppGroupContainer.databaseURL
            db = try Connection(dbURL.path)
            logger.info("Database opened at: \(dbURL.path)")

            initializeRepositories()
            migrateIfNeeded()
        } catch {
            logger.error("Failed to open database: \(error)")
        }
    }

    private func initializeRepositories() {
        guard let db = db else { return }

        migrationRepository = MigrationsRepository(db: db)
        userSettingsRepository = UserSettingsRepository(db: db)
        projectRepository = ProjectRepository(db: db)
        checklistRepository = ChecklistRepository(db: db)
        checklistItemRepository = ChecklistItemRepository(db: db)
        ideaRepository = IdeaRepository(db: db)
        tagRepository = TagRepository(db: db)
        expenseRepository = ExpenseRepository(db: db)
        expenseCategoryRepository = ExpenseCategoryRepository(db: db)
        noteRepository = NoteRepository(db: db)
        documentRepository = DocumentRepository(db: db)
        reminderRepository = ReminderRepository(db: db)
    }

    private func migrateIfNeeded() {
        guard let db = db else { return }

        migrationRepository?.createTableIfNotExists()

        let currentVersion = migrationRepository?.getLatestMigrationVersion() ?? 0

        if currentVersion > latestVersion {
            logger.warning("Database version \(currentVersion) is ahead of expected \(self.latestVersion)")
            return
        }

        if currentVersion == latestVersion {
            logger.info("Database is up to date (version \(currentVersion))")
            return
        }

        logger.info("Migrating database from version \(currentVersion) to \(self.latestVersion)")

        for version in (Int(currentVersion) + 1) ... latestVersion {
            do {
                switch version {
                case 1:
                    guard let userSettingsRepository else {
                        throw RuntimeError("UserSettingsRepository is unavailable")
                    }
                    userSettingsRepository.createTable()

                    guard userSettingsRepository.upsertCurrency(Currency.usd.rawValue) else {
                        throw RuntimeError("Failed to seed default currency")
                    }
                case 2:
                    try Migration_20260217_InitialSchema(db: db).execute()
                case 3:
                    try Migration_20260218_AddDocumentsTable(db: db).execute()
                case 4:
                    try Migration_20260218_AddRemindersTable(db: db).execute()
                case 5:
                    Migration_20260220_DocumentFilePath(db: db).execute()
                default:
                    throw RuntimeError("Unknown migration version: \(version)")
                }

                migrationRepository?.addMigrationVersion()
            } catch {
                logger.error("Database migration failed at version \(version): \(error.localizedDescription)")
                return
            }
        }

        logger.info("Database migration completed to version \(self.latestVersion)")
    }
}
