import Foundation
import SQLite
import os

class ChecklistRepository {
    private let table = Table("checklists")

    private let idColumn = Expression<String>("id")
    private let projectIdColumn = Expression<String>("project_id")
    private let nameColumn = Expression<String>("name")
    private let sortOrderColumn = Expression<Int>("sort_order")
    private let createdAtColumn = Expression<Date>("created_at")
    private let updatedAtColumn = Expression<Date>("updated_at")

    private let db: Connection
    private let logger: Logger

    init(db: Connection, logger: Logger? = nil) {
        self.db = db
        self.logger = logger ?? Logger(
            subsystem: Bundle.main.bundleIdentifier ?? "-",
            category: "ChecklistRepository"
        )
    }

    func fetchByProjectId(projectId: UUID) -> [Checklist] {
        var checklists: [Checklist] = []
        do {
            let query = table.filter(projectIdColumn == projectId.uuidString)
                .order(sortOrderColumn.asc)
            for row in try db.prepare(query) {
                if let checklist = mapRow(row) {
                    checklists.append(checklist)
                }
            }
        } catch {
            logger.error("Failed to fetch checklists for project \(projectId): \(error)")
        }
        return checklists
    }

    func fetchById(id: UUID) -> Checklist? {
        do {
            let query = table.filter(idColumn == id.uuidString)
            if let row = try db.pluck(query) {
                return mapRow(row)
            }
        } catch {
            logger.error("Failed to fetch checklist by id \(id): \(error)")
        }
        return nil
    }

    func insert(_ checklist: Checklist) -> Bool {
        do {
            try db.run(table.insert(
                idColumn <- checklist.id.uuidString,
                projectIdColumn <- checklist.projectId.uuidString,
                nameColumn <- checklist.name,
                sortOrderColumn <- checklist.sortOrder,
                createdAtColumn <- checklist.createdAt,
                updatedAtColumn <- checklist.updatedAt
            ))
            logger.info("Inserted checklist: \(checklist.id)")
            return true
        } catch {
            logger.error("Failed to insert checklist: \(error)")
            return false
        }
    }

    func update(_ checklist: Checklist) -> Bool {
        let record = table.filter(idColumn == checklist.id.uuidString)
        do {
            try db.run(record.update(
                nameColumn <- checklist.name,
                sortOrderColumn <- checklist.sortOrder,
                updatedAtColumn <- Date()
            ))
            logger.info("Updated checklist: \(checklist.id)")
            return true
        } catch {
            logger.error("Failed to update checklist: \(error)")
            return false
        }
    }

    func delete(id: UUID) -> Bool {
        let record = table.filter(idColumn == id.uuidString)
        do {
            try db.run(record.delete())
            logger.info("Deleted checklist: \(id)")
            return true
        } catch {
            logger.error("Failed to delete checklist: \(error)")
            return false
        }
    }

    func deleteByProjectId(projectId: UUID) -> Bool {
        let records = table.filter(projectIdColumn == projectId.uuidString)
        do {
            try db.run(records.delete())
            logger.info("Deleted checklists for project: \(projectId)")
            return true
        } catch {
            logger.error("Failed to delete checklists for project: \(error)")
            return false
        }
    }

    func countByProjectId(projectId: UUID) -> Int {
        do {
            return try db.scalar(table.filter(projectIdColumn == projectId.uuidString).count)
        } catch {
            logger.error("Failed to count checklists: \(error)")
            return 0
        }
    }

    private func mapRow(_ row: Row) -> Checklist? {
        guard let id = UUID(uuidString: row[idColumn]),
              let projectId = UUID(uuidString: row[projectIdColumn])
        else { return nil }

        return Checklist(
            id: id,
            projectId: projectId,
            name: row[nameColumn],
            sortOrder: row[sortOrderColumn],
            createdAt: row[createdAtColumn],
            updatedAt: row[updatedAtColumn]
        )
    }
}
