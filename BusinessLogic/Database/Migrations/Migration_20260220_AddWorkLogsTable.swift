import Foundation
import SQLite
import os

class Migration_20260220_AddWorkLogsTable {
    private let migrationName = "20260220_AddWorkLogsTable"
    private let db: Connection

    init(db: Connection) {
        self.db = db
    }

    func execute() throws {
        let logger = Logger(
            subsystem: "dev.mgorbatyuk.CreativityHub.migrations",
            category: migrationName
        )

        let table = Table("work_logs")
        try db.run(table.create(ifNotExists: true) { t in
            t.column(Expression<String>("id"), primaryKey: true)
            t.column(Expression<String>("project_id"))
            t.column(Expression<String?>("title"))
            t.column(Expression<String?>("linked_checklist_item_id"))
            t.column(Expression<Int>("total_minutes"))
            t.column(Expression<Date>("created_at"))
            t.column(Expression<Date>("updated_at"))
        })
        try db.run(table.createIndex(Expression<String>("project_id"), ifNotExists: true))
        logger.debug("Migration \(self.migrationName) executed successfully")
    }
}
