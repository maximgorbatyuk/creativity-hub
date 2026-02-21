import Foundation
import SQLite
import os

class WorkLogRepository {
    private let table = Table("work_logs")

    private let idColumn = Expression<String>("id")
    private let projectIdColumn = Expression<String>("project_id")
    private let titleColumn = Expression<String?>("title")
    private let linkedChecklistItemIdColumn = Expression<String?>("linked_checklist_item_id")
    private let totalMinutesColumn = Expression<Int>("total_minutes")
    private let createdAtColumn = Expression<Date>("created_at")
    private let updatedAtColumn = Expression<Date>("updated_at")

    private let db: Connection
    private let logger: Logger

    init(db: Connection, logger: Logger? = nil) {
        self.db = db
        self.logger = logger ?? Logger(
            subsystem: Bundle.main.bundleIdentifier ?? "-",
            category: "WorkLogRepository"
        )
    }

    func fetchAll() -> [WorkLog] {
        var workLogs: [WorkLog] = []
        do {
            for row in try db.prepare(table.order(createdAtColumn.desc)) {
                if let workLog = mapRow(row) {
                    workLogs.append(workLog)
                }
            }
        } catch {
            logger.error("Failed to fetch all work logs: \(error)")
        }
        return workLogs
    }

    func deleteAll() {
        do {
            try db.run(table.delete())
        } catch {
            logger.error("Failed to delete all work logs: \(error)")
        }
    }

    func fetchByProjectId(projectId: UUID) -> [WorkLog] {
        var workLogs: [WorkLog] = []
        do {
            let query = table.filter(projectIdColumn == projectId.uuidString)
                .order(createdAtColumn.desc)
            for row in try db.prepare(query) {
                if let workLog = mapRow(row) {
                    workLogs.append(workLog)
                }
            }
        } catch {
            logger.error("Failed to fetch work logs for project \(projectId): \(error)")
        }
        return workLogs
    }

    func fetchByChecklistItemId(checklistItemId: UUID) -> [WorkLog] {
        var workLogs: [WorkLog] = []
        do {
            let query = table.filter(linkedChecklistItemIdColumn == checklistItemId.uuidString)
                .order(createdAtColumn.desc)
            for row in try db.prepare(query) {
                if let workLog = mapRow(row) {
                    workLogs.append(workLog)
                }
            }
        } catch {
            logger.error("Failed to fetch work logs for checklist item \(checklistItemId): \(error)")
        }
        return workLogs
    }

    func fetchById(id: UUID) -> WorkLog? {
        do {
            let query = table.filter(idColumn == id.uuidString)
            if let row = try db.pluck(query) {
                return mapRow(row)
            }
        } catch {
            logger.error("Failed to fetch work log by id \(id): \(error)")
        }
        return nil
    }

    func insert(_ workLog: WorkLog) -> Bool {
        do {
            try db.run(table.insert(
                idColumn <- workLog.id.uuidString,
                projectIdColumn <- workLog.projectId.uuidString,
                titleColumn <- workLog.title,
                linkedChecklistItemIdColumn <- workLog.linkedChecklistItemId?.uuidString,
                totalMinutesColumn <- workLog.totalMinutes,
                createdAtColumn <- workLog.createdAt,
                updatedAtColumn <- workLog.updatedAt
            ))
            logger.info("Inserted work log: \(workLog.id)")
            return true
        } catch {
            logger.error("Failed to insert work log: \(error)")
            return false
        }
    }

    func update(_ workLog: WorkLog) -> Bool {
        let record = table.filter(idColumn == workLog.id.uuidString)
        do {
            try db.run(record.update(
                titleColumn <- workLog.title,
                linkedChecklistItemIdColumn <- workLog.linkedChecklistItemId?.uuidString,
                totalMinutesColumn <- workLog.totalMinutes,
                updatedAtColumn <- Date()
            ))
            logger.info("Updated work log: \(workLog.id)")
            return true
        } catch {
            logger.error("Failed to update work log: \(error)")
            return false
        }
    }

    func delete(id: UUID) -> Bool {
        let record = table.filter(idColumn == id.uuidString)
        do {
            try db.run(record.delete())
            logger.info("Deleted work log: \(id)")
            return true
        } catch {
            logger.error("Failed to delete work log: \(id) - \(error)")
            return false
        }
    }

    func deleteByProjectId(projectId: UUID) -> Bool {
        let records = table.filter(projectIdColumn == projectId.uuidString)
        do {
            try db.run(records.delete())
            logger.info("Deleted work logs for project: \(projectId)")
            return true
        } catch {
            logger.error("Failed to delete work logs for project: \(error)")
            return false
        }
    }

    func countByProjectId(projectId: UUID) -> Int {
        do {
            return try db.scalar(table.filter(projectIdColumn == projectId.uuidString).count)
        } catch {
            logger.error("Failed to count work logs: \(error)")
            return 0
        }
    }

    func totalMinutesByProjectId(projectId: UUID) -> Int {
        var total = 0
        do {
            let query = table.filter(projectIdColumn == projectId.uuidString)
            for row in try db.prepare(query) {
                total += row[totalMinutesColumn]
            }
        } catch {
            logger.error("Failed to sum work log minutes for project \(projectId): \(error)")
        }
        return total
    }

    func totalHoursByProjectId(projectId: UUID) -> Int {
        totalMinutesByProjectId(projectId: projectId) / 60
    }

    func totalMinutesAll() -> Int {
        var total = 0
        do {
            for row in try db.prepare(table) {
                total += row[totalMinutesColumn]
            }
        } catch {
            logger.error("Failed to sum total work log minutes: \(error)")
        }
        return total
    }

    func detachChecklistItem(checklistItemId: UUID) -> Bool {
        let records = table.filter(linkedChecklistItemIdColumn == checklistItemId.uuidString)
        do {
            try db.run(records.update(
                linkedChecklistItemIdColumn <- nil as String?,
                updatedAtColumn <- Date()
            ))
            logger.info("Detached checklist item \(checklistItemId) from work logs")
            return true
        } catch {
            logger.error("Failed to detach checklist item from work logs: \(error)")
            return false
        }
    }

    // MARK: - Row Mapping

    private func mapRow(_ row: Row) -> WorkLog? {
        guard let id = UUID(uuidString: row[idColumn]),
              let projectId = UUID(uuidString: row[projectIdColumn])
        else { return nil }

        let linkedItemId = row[linkedChecklistItemIdColumn].flatMap { UUID(uuidString: $0) }

        return WorkLog(
            id: id,
            projectId: projectId,
            title: row[titleColumn],
            linkedChecklistItemId: linkedItemId,
            totalMinutes: row[totalMinutesColumn],
            createdAt: row[createdAtColumn],
            updatedAt: row[updatedAtColumn]
        )
    }
}
