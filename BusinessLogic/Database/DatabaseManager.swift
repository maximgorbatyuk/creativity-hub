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

    private let latestVersion = 2

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

    private init() {
        setupDatabase()
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
