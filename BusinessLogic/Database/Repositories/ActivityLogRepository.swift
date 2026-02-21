import Foundation
import SQLite
import os

class ActivityLogRepository {
    private let table = Table("activity_logs")

    private let idColumn = Expression<String>("id")
    private let projectIdColumn = Expression<String>("project_id")
    private let entityTypeColumn = Expression<String>("entity_type")
    private let actionTypeColumn = Expression<String>("action_type")
    private let createdAtColumn = Expression<Date>("created_at")

    private let db: Connection
    private let logger: Logger

    init(db: Connection, logger: Logger? = nil) {
        self.db = db
        self.logger = logger ?? Logger(
            subsystem: Bundle.main.bundleIdentifier ?? "-",
            category: "ActivityLogRepository"
        )
    }

    func fetchByProjectId(projectId: UUID) -> [ActivityLog] {
        var logs: [ActivityLog] = []
        do {
            let query = table
                .filter(projectIdColumn == projectId.uuidString)
                .order(createdAtColumn.asc)

            for row in try db.prepare(query) {
                if let log = mapRow(row) {
                    logs.append(log)
                }
            }
        } catch {
            logger.error("Failed to fetch activity logs for project \(projectId): \(error)")
        }
        return logs
    }

    func fetchDailyCountsByProjectId(projectId: UUID, since: Date, until: Date) -> [Date: Int] {
        let logs = fetchByProjectId(projectId: projectId)
            .filter { $0.createdAt >= since && $0.createdAt <= until }

        var result: [Date: Int] = [:]
        let calendar = Calendar.current

        for log in logs {
            let day = calendar.startOfDay(for: log.createdAt)
            result[day, default: 0] += 1
        }

        return result
    }

    func insert(_ activityLog: ActivityLog) -> Bool {
        do {
            try db.run(table.insert(
                idColumn <- activityLog.id.uuidString,
                projectIdColumn <- activityLog.projectId.uuidString,
                entityTypeColumn <- activityLog.entityType.rawValue,
                actionTypeColumn <- activityLog.actionType.rawValue,
                createdAtColumn <- activityLog.createdAt
            ))
            return true
        } catch {
            logger.error("Failed to insert activity log: \(error)")
            return false
        }
    }

    func deleteOlderThan(_ cutoffDate: Date) -> Int {
        let records = table.filter(createdAtColumn < cutoffDate)
        do {
            return try db.run(records.delete())
        } catch {
            logger.error("Failed to delete old activity logs: \(error)")
            return 0
        }
    }

    func deleteByProjectId(projectId: UUID) -> Bool {
        let records = table.filter(projectIdColumn == projectId.uuidString)
        do {
            try db.run(records.delete())
            return true
        } catch {
            logger.error("Failed to delete activity logs for project \(projectId): \(error)")
            return false
        }
    }

    func deleteAll() {
        do {
            try db.run(table.delete())
        } catch {
            logger.error("Failed to delete all activity logs: \(error)")
        }
    }

    private func mapRow(_ row: Row) -> ActivityLog? {
        guard let id = UUID(uuidString: row[idColumn]),
              let projectId = UUID(uuidString: row[projectIdColumn]),
              let entityType = ActivityEntityType(rawValue: row[entityTypeColumn]),
              let actionType = ActivityActionType(rawValue: row[actionTypeColumn])
        else {
            return nil
        }

        return ActivityLog(
            id: id,
            projectId: projectId,
            entityType: entityType,
            actionType: actionType,
            createdAt: row[createdAtColumn]
        )
    }
}
