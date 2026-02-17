import Foundation
import SQLite
import os

class ChecklistItemRepository {
    private let table = Table("checklist_items")

    private let idColumn = Expression<String>("id")
    private let checklistIdColumn = Expression<String>("checklist_id")
    private let nameColumn = Expression<String>("name")
    private let isCompletedColumn = Expression<Bool>("is_completed")
    private let dueDateColumn = Expression<Date?>("due_date")
    private let priorityColumn = Expression<String>("priority")
    private let estimatedCostColumn = Expression<String?>("estimated_cost")
    private let estimatedCostCurrencyColumn = Expression<String?>("estimated_cost_currency")
    private let notesColumn = Expression<String?>("notes")
    private let sortOrderColumn = Expression<Int>("sort_order")
    private let createdAtColumn = Expression<Date>("created_at")
    private let updatedAtColumn = Expression<Date>("updated_at")

    private let db: Connection
    private let logger: Logger

    init(db: Connection, logger: Logger? = nil) {
        self.db = db
        self.logger = logger ?? Logger(
            subsystem: Bundle.main.bundleIdentifier ?? "-",
            category: "ChecklistItemRepository"
        )
    }

    func fetchByChecklistId(checklistId: UUID) -> [ChecklistItem] {
        var items: [ChecklistItem] = []
        do {
            let query = table.filter(checklistIdColumn == checklistId.uuidString)
                .order(sortOrderColumn.asc)
            for row in try db.prepare(query) {
                if let item = mapRow(row) {
                    items.append(item)
                }
            }
        } catch {
            logger.error("Failed to fetch items for checklist \(checklistId): \(error)")
        }
        return items
    }

    func fetchById(id: UUID) -> ChecklistItem? {
        do {
            let query = table.filter(idColumn == id.uuidString)
            if let row = try db.pluck(query) {
                return mapRow(row)
            }
        } catch {
            logger.error("Failed to fetch checklist item by id \(id): \(error)")
        }
        return nil
    }

    func fetchOverdueItems() -> [ChecklistItem] {
        var items: [ChecklistItem] = []
        let now = Date()
        do {
            let query = table.filter(
                isCompletedColumn == false && dueDateColumn < now
            ).order(dueDateColumn.asc)
            for row in try db.prepare(query) {
                if let item = mapRow(row) {
                    items.append(item)
                }
            }
        } catch {
            logger.error("Failed to fetch overdue items: \(error)")
        }
        return items
    }

    func insert(_ item: ChecklistItem) -> Bool {
        do {
            try db.run(table.insert(
                idColumn <- item.id.uuidString,
                checklistIdColumn <- item.checklistId.uuidString,
                nameColumn <- item.name,
                isCompletedColumn <- item.isCompleted,
                dueDateColumn <- item.dueDate,
                priorityColumn <- item.priority.rawValue,
                estimatedCostColumn <- item.estimatedCost.map { "\($0)" },
                estimatedCostCurrencyColumn <- item.estimatedCostCurrency?.rawValue,
                notesColumn <- item.notes,
                sortOrderColumn <- item.sortOrder,
                createdAtColumn <- item.createdAt,
                updatedAtColumn <- item.updatedAt
            ))
            logger.info("Inserted checklist item: \(item.id)")
            return true
        } catch {
            logger.error("Failed to insert checklist item: \(error)")
            return false
        }
    }

    func update(_ item: ChecklistItem) -> Bool {
        let record = table.filter(idColumn == item.id.uuidString)
        do {
            try db.run(record.update(
                nameColumn <- item.name,
                isCompletedColumn <- item.isCompleted,
                dueDateColumn <- item.dueDate,
                priorityColumn <- item.priority.rawValue,
                estimatedCostColumn <- item.estimatedCost.map { "\($0)" },
                estimatedCostCurrencyColumn <- item.estimatedCostCurrency?.rawValue,
                notesColumn <- item.notes,
                sortOrderColumn <- item.sortOrder,
                updatedAtColumn <- Date()
            ))
            logger.info("Updated checklist item: \(item.id)")
            return true
        } catch {
            logger.error("Failed to update checklist item: \(error)")
            return false
        }
    }

    func toggleCompletion(id: UUID) -> Bool {
        let record = table.filter(idColumn == id.uuidString)
        do {
            if let row = try db.pluck(record) {
                let current = row[isCompletedColumn]
                try db.run(record.update(
                    isCompletedColumn <- !current,
                    updatedAtColumn <- Date()
                ))
                logger.info("Toggled checklist item \(id) to \(!current)")
                return true
            }
        } catch {
            logger.error("Failed to toggle checklist item: \(error)")
        }
        return false
    }

    func delete(id: UUID) -> Bool {
        let record = table.filter(idColumn == id.uuidString)
        do {
            try db.run(record.delete())
            logger.info("Deleted checklist item: \(id)")
            return true
        } catch {
            logger.error("Failed to delete checklist item: \(error)")
            return false
        }
    }

    func deleteByChecklistId(checklistId: UUID) -> Bool {
        let records = table.filter(checklistIdColumn == checklistId.uuidString)
        do {
            try db.run(records.delete())
            logger.info("Deleted items for checklist: \(checklistId)")
            return true
        } catch {
            logger.error("Failed to delete items for checklist: \(error)")
            return false
        }
    }

    func countByChecklistId(checklistId: UUID) -> Int {
        do {
            return try db.scalar(table.filter(checklistIdColumn == checklistId.uuidString).count)
        } catch {
            logger.error("Failed to count checklist items: \(error)")
            return 0
        }
    }

    func completedCountByChecklistId(checklistId: UUID) -> Int {
        do {
            return try db.scalar(
                table.filter(
                    checklistIdColumn == checklistId.uuidString && isCompletedColumn == true
                ).count
            )
        } catch {
            logger.error("Failed to count completed items: \(error)")
            return 0
        }
    }

    func search(query searchQuery: String) -> [ChecklistItem] {
        var items: [ChecklistItem] = []
        let pattern = "%\(searchQuery)%"
        do {
            let query = table.filter(
                nameColumn.like(pattern) || notesColumn.like(pattern)
            ).order(updatedAtColumn.desc)
            for row in try db.prepare(query) {
                if let item = mapRow(row) {
                    items.append(item)
                }
            }
        } catch {
            logger.error("Failed to search checklist items: \(error)")
        }
        return items
    }

    // MARK: - Row Mapping

    private func mapRow(_ row: Row) -> ChecklistItem? {
        guard let id = UUID(uuidString: row[idColumn]),
              let checklistId = UUID(uuidString: row[checklistIdColumn])
        else { return nil }

        let estimatedCost: Decimal? = row[estimatedCostColumn].flatMap { Decimal(string: $0) }
        let estimatedCostCurrency: Currency? = row[estimatedCostCurrencyColumn].flatMap { Currency(rawValue: $0) }
        let priority = ItemPriority(rawValue: row[priorityColumn]) ?? .none

        return ChecklistItem(
            id: id,
            checklistId: checklistId,
            name: row[nameColumn],
            isCompleted: row[isCompletedColumn],
            dueDate: row[dueDateColumn],
            priority: priority,
            estimatedCost: estimatedCost,
            estimatedCostCurrency: estimatedCostCurrency,
            notes: row[notesColumn],
            sortOrder: row[sortOrderColumn],
            createdAt: row[createdAtColumn],
            updatedAt: row[updatedAtColumn]
        )
    }
}
