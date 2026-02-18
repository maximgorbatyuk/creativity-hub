import Foundation
import SQLite
import os

class Migration_20260218_AddDocumentsTable {
    private let migrationName = "20260218_AddDocumentsTable"
    private let db: Connection

    init(db: Connection) {
        self.db = db
    }

    func execute() throws {
        let logger = Logger(
            subsystem: "dev.mgorbatyuk.CreativityHub.migrations",
            category: migrationName
        )

        let table = Table("documents")
        try db.run(table.create(ifNotExists: true) { t in
            t.column(Expression<String>("id"), primaryKey: true)
            t.column(Expression<String>("project_id"))
            t.column(Expression<String?>("name"))
            t.column(Expression<String>("file_type"), defaultValue: "other")
            t.column(Expression<String>("file_name"))
            t.column(Expression<Int64>("file_size"), defaultValue: 0)
            t.column(Expression<String?>("notes"))
            t.column(Expression<Date>("created_at"))
        })
        try db.run(table.createIndex(Expression<String>("project_id"), ifNotExists: true))
        logger.debug("Migration \(self.migrationName) executed successfully")
    }
}
