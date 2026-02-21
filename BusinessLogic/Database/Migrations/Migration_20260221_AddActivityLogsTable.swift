import Foundation
import SQLite
import os

class Migration_20260221_AddActivityLogsTable {
    private let migrationName = "20260221_AddActivityLogsTable"
    private let db: Connection

    init(db: Connection) {
        self.db = db
    }

    func execute() throws {
        let logger = Logger(
            subsystem: "dev.mgorbatyuk.CreativityHub.migrations",
            category: migrationName
        )

        let table = Table("activity_logs")
        try db.run(table.create(ifNotExists: true) { t in
            t.column(Expression<String>("id"), primaryKey: true)
            t.column(Expression<String>("project_id"))
            t.column(Expression<String>("entity_type"))
            t.column(Expression<String>("action_type"))
            t.column(Expression<Date>("created_at"))
        })

        try db.run(table.createIndex(Expression<String>("project_id"), ifNotExists: true))
        try db.run(table.createIndex(Expression<Date>("created_at"), ifNotExists: true))

        logger.debug("Migration \(self.migrationName) executed successfully")
    }
}
