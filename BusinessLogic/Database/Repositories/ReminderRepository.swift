import Foundation
import SQLite
import os

class ReminderRepository {
    private let table = Table("reminders")

    private let idColumn = Expression<String>("id")
    private let projectIdColumn = Expression<String>("project_id")
    private let titleColumn = Expression<String>("title")
    private let notesColumn = Expression<String?>("notes")
    private let dueDateColumn = Expression<Date?>("due_date")
    private let isCompletedColumn = Expression<Bool>("is_completed")
    private let priorityColumn = Expression<String>("priority")
    private let createdAtColumn = Expression<Date>("created_at")
    private let updatedAtColumn = Expression<Date>("updated_at")

    private let db: Connection
    private let logger: Logger

    init(db: Connection, logger: Logger? = nil) {
        self.db = db
        self.logger = logger ?? Logger(
            subsystem: Bundle.main.bundleIdentifier ?? "-",
            category: "ReminderRepository"
        )
    }

    func fetchAll() -> [Reminder] {
        var reminders: [Reminder] = []
        do {
            for row in try db.prepare(table.order(createdAtColumn.desc)) {
                if let reminder = mapRow(row) {
                    reminders.append(reminder)
                }
            }
        } catch {
            logger.error("Failed to fetch all reminders: \(error)")
        }
        return reminders
    }

    func deleteAll() {
        do {
            try db.run(table.delete())
        } catch {
            logger.error("Failed to delete all reminders: \(error)")
        }
    }

    func fetchByProjectId(projectId: UUID) -> [Reminder] {
        var reminders: [Reminder] = []
        do {
            let query = table.filter(projectIdColumn == projectId.uuidString)
                .order(isCompletedColumn.asc, dueDateColumn.asc, createdAtColumn.desc)
            for row in try db.prepare(query) {
                if let reminder = mapRow(row) {
                    reminders.append(reminder)
                }
            }
        } catch {
            logger.error("Failed to fetch reminders for project \(projectId): \(error)")
        }
        return reminders
    }

    func fetchById(id: UUID) -> Reminder? {
        do {
            let query = table.filter(idColumn == id.uuidString)
            if let row = try db.pluck(query) {
                return mapRow(row)
            }
        } catch {
            logger.error("Failed to fetch reminder by id \(id): \(error)")
        }
        return nil
    }

    func insert(_ reminder: Reminder) -> Bool {
        do {
            try db.run(table.insert(
                idColumn <- reminder.id.uuidString,
                projectIdColumn <- reminder.projectId.uuidString,
                titleColumn <- reminder.title,
                notesColumn <- reminder.notes,
                dueDateColumn <- reminder.dueDate,
                isCompletedColumn <- reminder.isCompleted,
                priorityColumn <- reminder.priority.rawValue,
                createdAtColumn <- reminder.createdAt,
                updatedAtColumn <- reminder.updatedAt
            ))
            logger.info("Inserted reminder: \(reminder.id)")
            return true
        } catch {
            logger.error("Failed to insert reminder: \(error)")
            return false
        }
    }

    func update(_ reminder: Reminder) -> Bool {
        let record = table.filter(idColumn == reminder.id.uuidString)
        do {
            try db.run(record.update(
                titleColumn <- reminder.title,
                notesColumn <- reminder.notes,
                dueDateColumn <- reminder.dueDate,
                isCompletedColumn <- reminder.isCompleted,
                priorityColumn <- reminder.priority.rawValue,
                updatedAtColumn <- Date()
            ))
            logger.info("Updated reminder: \(reminder.id)")
            return true
        } catch {
            logger.error("Failed to update reminder: \(error)")
            return false
        }
    }

    func delete(id: UUID) -> Bool {
        let record = table.filter(idColumn == id.uuidString)
        do {
            try db.run(record.delete())
            logger.info("Deleted reminder: \(id)")
            return true
        } catch {
            logger.error("Failed to delete reminder: \(error)")
            return false
        }
    }

    func deleteByProjectId(projectId: UUID) -> Bool {
        let records = table.filter(projectIdColumn == projectId.uuidString)
        do {
            try db.run(records.delete())
            logger.info("Deleted reminders for project: \(projectId)")
            return true
        } catch {
            logger.error("Failed to delete reminders for project: \(error)")
            return false
        }
    }

    func toggleCompleted(id: UUID, isCompleted: Bool) -> Bool {
        let record = table.filter(idColumn == id.uuidString)
        do {
            try db.run(record.update(
                isCompletedColumn <- isCompleted,
                updatedAtColumn <- Date()
            ))
            logger.info("Toggled completed for reminder \(id): \(isCompleted)")
            return true
        } catch {
            logger.error("Failed to toggle completed for reminder \(id): \(error)")
            return false
        }
    }

    func countByProjectId(projectId: UUID) -> Int {
        do {
            return try db.scalar(table.filter(projectIdColumn == projectId.uuidString).count)
        } catch {
            logger.error("Failed to count reminders: \(error)")
            return 0
        }
    }

    func fetchUpcoming(limit: Int = 10) -> [Reminder] {
        var reminders: [Reminder] = []
        let now = Date()
        do {
            let query = table.filter(
                isCompletedColumn == false &&
                dueDateColumn != nil &&
                dueDateColumn >= now
            )
                .order(dueDateColumn.asc, createdAtColumn.desc)
                .limit(limit)
            for row in try db.prepare(query) {
                if let reminder = mapRow(row) {
                    reminders.append(reminder)
                }
            }
        } catch {
            logger.error("Failed to fetch upcoming reminders: \(error)")
        }
        return reminders
    }

    func fetchOverdue() -> [Reminder] {
        var reminders: [Reminder] = []
        let now = Date()
        do {
            let query = table.filter(
                isCompletedColumn == false && dueDateColumn < now
            ).order(dueDateColumn.asc)
            for row in try db.prepare(query) {
                if let reminder = mapRow(row) {
                    reminders.append(reminder)
                }
            }
        } catch {
            logger.error("Failed to fetch overdue reminders: \(error)")
        }
        return reminders
    }

    func search(query searchQuery: String) -> [Reminder] {
        var reminders: [Reminder] = []
        let pattern = "%\(searchQuery)%"
        do {
            let query = table.filter(
                titleColumn.like(pattern) || notesColumn.like(pattern)
            ).order(updatedAtColumn.desc)
            for row in try db.prepare(query) {
                if let reminder = mapRow(row) {
                    reminders.append(reminder)
                }
            }
        } catch {
            logger.error("Failed to search reminders: \(error)")
        }
        return reminders
    }

    // MARK: - Row Mapping

    private func mapRow(_ row: Row) -> Reminder? {
        guard let id = UUID(uuidString: row[idColumn]),
              let projectId = UUID(uuidString: row[projectIdColumn])
        else { return nil }

        let priority = ItemPriority(rawValue: row[priorityColumn]) ?? .none

        return Reminder(
            id: id,
            projectId: projectId,
            title: row[titleColumn],
            notes: row[notesColumn],
            dueDate: row[dueDateColumn],
            isCompleted: row[isCompletedColumn],
            priority: priority,
            createdAt: row[createdAtColumn],
            updatedAt: row[updatedAtColumn]
        )
    }
}
