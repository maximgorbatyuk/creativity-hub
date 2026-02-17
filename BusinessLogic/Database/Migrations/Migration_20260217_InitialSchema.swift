import Foundation
import SQLite
import os

class Migration_20260217_InitialSchema {
    private let migrationName = "20260217_InitialSchema"
    private let db: Connection

    init(db: Connection) {
        self.db = db
    }

    func execute() {
        let logger = Logger(
            subsystem: "dev.mgorbatyuk.CreativityHub.migrations",
            category: migrationName
        )

        do {
            try createProjectsTable(logger: logger)
            try createChecklistsTable(logger: logger)
            try createChecklistItemsTable(logger: logger)
            try createIdeasTable(logger: logger)
            try createTagsTable(logger: logger)
            try createIdeaTagsTable(logger: logger)
            try createExpenseCategoriesTable(logger: logger)
            try createExpensesTable(logger: logger)
            try createNotesTable(logger: logger)
            logger.debug("Migration \(self.migrationName) executed successfully")
        } catch {
            logger.error("Unable to execute migration \(self.migrationName): \(error)")
        }
    }

    // MARK: - Table Creation

    private func createProjectsTable(logger: Logger) throws {
        let table = Table("projects")
        try db.run(table.create(ifNotExists: true) { t in
            t.column(Expression<String>("id"), primaryKey: true)
            t.column(Expression<String>("name"))
            t.column(Expression<String?>("description"))
            t.column(Expression<String?>("cover_color"))
            t.column(Expression<String?>("cover_image_path"))
            t.column(Expression<String>("status"), defaultValue: "active")
            t.column(Expression<Date?>("start_date"))
            t.column(Expression<Date?>("target_date"))
            t.column(Expression<String?>("budget"))
            t.column(Expression<String?>("budget_currency"))
            t.column(Expression<Bool>("is_pinned"), defaultValue: false)
            t.column(Expression<Int>("sort_order"), defaultValue: 0)
            t.column(Expression<Date>("created_at"))
            t.column(Expression<Date>("updated_at"))
        })
        logger.debug("Projects table created")
    }

    private func createChecklistsTable(logger: Logger) throws {
        let table = Table("checklists")
        try db.run(table.create(ifNotExists: true) { t in
            t.column(Expression<String>("id"), primaryKey: true)
            t.column(Expression<String>("project_id"))
            t.column(Expression<String>("name"))
            t.column(Expression<Int>("sort_order"), defaultValue: 0)
            t.column(Expression<Date>("created_at"))
            t.column(Expression<Date>("updated_at"))
        })
        try db.run(table.createIndex(Expression<String>("project_id"), ifNotExists: true))
        logger.debug("Checklists table created")
    }

    private func createChecklistItemsTable(logger: Logger) throws {
        let table = Table("checklist_items")
        try db.run(table.create(ifNotExists: true) { t in
            t.column(Expression<String>("id"), primaryKey: true)
            t.column(Expression<String>("checklist_id"))
            t.column(Expression<String>("name"))
            t.column(Expression<Bool>("is_completed"), defaultValue: false)
            t.column(Expression<Date?>("due_date"))
            t.column(Expression<String>("priority"), defaultValue: "none")
            t.column(Expression<String?>("estimated_cost"))
            t.column(Expression<String?>("estimated_cost_currency"))
            t.column(Expression<String?>("notes"))
            t.column(Expression<Int>("sort_order"), defaultValue: 0)
            t.column(Expression<Date>("created_at"))
            t.column(Expression<Date>("updated_at"))
        })
        try db.run(table.createIndex(Expression<String>("checklist_id"), ifNotExists: true))
        logger.debug("Checklist items table created")
    }

    private func createIdeasTable(logger: Logger) throws {
        let table = Table("ideas")
        try db.run(table.create(ifNotExists: true) { t in
            t.column(Expression<String>("id"), primaryKey: true)
            t.column(Expression<String>("project_id"))
            t.column(Expression<String?>("url"))
            t.column(Expression<String>("title"))
            t.column(Expression<String?>("thumbnail_url"))
            t.column(Expression<String?>("source_domain"))
            t.column(Expression<String>("source_type"), defaultValue: "other")
            t.column(Expression<String?>("notes"))
            t.column(Expression<Date>("created_at"))
            t.column(Expression<Date>("updated_at"))
        })
        try db.run(table.createIndex(Expression<String>("project_id"), ifNotExists: true))
        logger.debug("Ideas table created")
    }

    private func createTagsTable(logger: Logger) throws {
        let table = Table("tags")
        try db.run(table.create(ifNotExists: true) { t in
            t.column(Expression<String>("id"), primaryKey: true)
            t.column(Expression<String>("name"))
            t.column(Expression<String>("color"), defaultValue: "blue")
        })
        logger.debug("Tags table created")
    }

    private func createIdeaTagsTable(logger: Logger) throws {
        let table = Table("idea_tags")
        try db.run(table.create(ifNotExists: true) { t in
            t.column(Expression<String>("idea_id"))
            t.column(Expression<String>("tag_id"))
        })
        try db.run(table.createIndex(Expression<String>("idea_id"), ifNotExists: true))
        try db.run(table.createIndex(Expression<String>("tag_id"), ifNotExists: true))
        logger.debug("Idea tags table created")
    }

    private func createExpenseCategoriesTable(logger: Logger) throws {
        let table = Table("expense_categories")
        try db.run(table.create(ifNotExists: true) { t in
            t.column(Expression<String>("id"), primaryKey: true)
            t.column(Expression<String>("project_id"))
            t.column(Expression<String>("name"))
            t.column(Expression<String?>("budget_limit"))
            t.column(Expression<String?>("budget_currency"))
            t.column(Expression<String>("color"), defaultValue: "blue")
            t.column(Expression<Int>("sort_order"), defaultValue: 0)
            t.column(Expression<Date>("created_at"))
            t.column(Expression<Date>("updated_at"))
        })
        try db.run(table.createIndex(Expression<String>("project_id"), ifNotExists: true))
        logger.debug("Expense categories table created")
    }

    private func createExpensesTable(logger: Logger) throws {
        let table = Table("expenses")
        try db.run(table.create(ifNotExists: true) { t in
            t.column(Expression<String>("id"), primaryKey: true)
            t.column(Expression<String>("project_id"))
            t.column(Expression<String?>("category_id"))
            t.column(Expression<String>("amount"))
            t.column(Expression<String>("currency"))
            t.column(Expression<Date>("date"))
            t.column(Expression<String?>("vendor"))
            t.column(Expression<String>("status"), defaultValue: "planned")
            t.column(Expression<String?>("receipt_image_path"))
            t.column(Expression<String?>("notes"))
            t.column(Expression<String?>("linked_checklist_item_id"))
            t.column(Expression<Date>("created_at"))
            t.column(Expression<Date>("updated_at"))
        })
        try db.run(table.createIndex(Expression<String>("project_id"), ifNotExists: true))
        try db.run(table.createIndex(Expression<String?>("category_id"), ifNotExists: true))
        logger.debug("Expenses table created")
    }

    private func createNotesTable(logger: Logger) throws {
        let table = Table("notes")
        try db.run(table.create(ifNotExists: true) { t in
            t.column(Expression<String>("id"), primaryKey: true)
            t.column(Expression<String>("project_id"))
            t.column(Expression<String>("title"))
            t.column(Expression<String>("content"), defaultValue: "")
            t.column(Expression<Bool>("is_pinned"), defaultValue: false)
            t.column(Expression<Int>("sort_order"), defaultValue: 0)
            t.column(Expression<Date>("created_at"))
            t.column(Expression<Date>("updated_at"))
        })
        try db.run(table.createIndex(Expression<String>("project_id"), ifNotExists: true))
        logger.debug("Notes table created")
    }
}
