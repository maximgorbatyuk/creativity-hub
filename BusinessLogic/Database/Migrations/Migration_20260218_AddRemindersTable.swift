import Foundation
import SQLite
import os

class Migration_20260218_AddRemindersTable {
    private let migrationName = "20260218_AddRemindersTable"
    private let db: Connection

    init(db: Connection) {
        self.db = db
    }

    func execute() throws {
        let logger = Logger(
            subsystem: "dev.mgorbatyuk.CreativityHub.migrations",
            category: migrationName
        )

        let table = Table("reminders")
        try db.run(table.create(ifNotExists: true) { t in
            t.column(Expression<String>("id"), primaryKey: true)
            t.column(Expression<String>("project_id"))
            t.column(Expression<String>("title"))
            t.column(Expression<String?>("notes"))
            t.column(Expression<Date?>("due_date"))
            t.column(Expression<Bool>("is_completed"), defaultValue: false)
            t.column(Expression<String>("priority"), defaultValue: "none")
            t.column(Expression<Date>("created_at"))
            t.column(Expression<Date>("updated_at"))
        })
        try db.run(table.createIndex(Expression<String>("project_id"), ifNotExists: true))
        logger.debug("Migration \(self.migrationName) executed successfully")
    }
}
