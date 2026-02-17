import Foundation
import SQLite
import os

class MigrationsRepository {
    private let table = Table("migrations")
    private let idColumn = Expression<Int64>("id")
    private let dateColumn = Expression<Date>("date")

    private let db: Connection
    private let logger: Logger

    init(db: Connection, logger: Logger? = nil) {
        self.db = db
        self.logger = logger ?? Logger(
            subsystem: Bundle.main.bundleIdentifier ?? "-",
            category: "MigrationsRepository"
        )
    }

    func createTableIfNotExists() {
        do {
            try db.run(table.create(ifNotExists: true) { t in
                t.column(idColumn, primaryKey: .autoincrement)
                t.column(dateColumn)
            })
        } catch {
            logger.error("Failed to create migrations table: \(error)")
        }
    }

    func getLatestMigrationVersion() -> Int64 {
        do {
            return try db.scalar(table.select(idColumn.max)) ?? 0
        } catch {
            logger.error("Failed to get latest migration version: \(error)")
            return 0
        }
    }

    func addMigrationVersion() {
        do {
            try db.run(table.insert(dateColumn <- Date()))
        } catch {
            logger.error("Failed to add migration version: \(error)")
        }
    }
}
