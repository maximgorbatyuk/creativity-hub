import Foundation
import SQLite
import os

class ExpenseCategoryRepository {
    private let table = Table("expense_categories")

    private let idColumn = Expression<String>("id")
    private let projectIdColumn = Expression<String>("project_id")
    private let nameColumn = Expression<String>("name")
    private let budgetLimitColumn = Expression<String?>("budget_limit")
    private let budgetCurrencyColumn = Expression<String?>("budget_currency")
    private let colorColumn = Expression<String>("color")
    private let sortOrderColumn = Expression<Int>("sort_order")
    private let createdAtColumn = Expression<Date>("created_at")
    private let updatedAtColumn = Expression<Date>("updated_at")

    private let db: Connection
    private let logger: Logger

    init(db: Connection, logger: Logger? = nil) {
        self.db = db
        self.logger = logger ?? Logger(
            subsystem: Bundle.main.bundleIdentifier ?? "-",
            category: "ExpenseCategoryRepository"
        )
    }

    func fetchAll() -> [ExpenseCategory] {
        var categories: [ExpenseCategory] = []
        do {
            for row in try db.prepare(table.order(sortOrderColumn.asc)) {
                if let category = mapRow(row) {
                    categories.append(category)
                }
            }
        } catch {
            logger.error("Failed to fetch all expense categories: \(error)")
        }
        return categories
    }

    func deleteAll() {
        do {
            try db.run(table.delete())
        } catch {
            logger.error("Failed to delete all expense categories: \(error)")
        }
    }

    func fetchByProjectId(projectId: UUID) -> [ExpenseCategory] {
        var categories: [ExpenseCategory] = []
        do {
            let query = table.filter(projectIdColumn == projectId.uuidString)
                .order(sortOrderColumn.asc)
            for row in try db.prepare(query) {
                if let category = mapRow(row) {
                    categories.append(category)
                }
            }
        } catch {
            logger.error("Failed to fetch categories for project \(projectId): \(error)")
        }
        return categories
    }

    func fetchById(id: UUID) -> ExpenseCategory? {
        do {
            let query = table.filter(idColumn == id.uuidString)
            if let row = try db.pluck(query) {
                return mapRow(row)
            }
        } catch {
            logger.error("Failed to fetch category by id \(id): \(error)")
        }
        return nil
    }

    func insert(_ category: ExpenseCategory) -> Bool {
        do {
            try db.run(table.insert(
                idColumn <- category.id.uuidString,
                projectIdColumn <- category.projectId.uuidString,
                nameColumn <- category.name,
                budgetLimitColumn <- category.budgetLimit.map { "\($0)" },
                budgetCurrencyColumn <- category.budgetCurrency?.rawValue,
                colorColumn <- category.color,
                sortOrderColumn <- category.sortOrder,
                createdAtColumn <- category.createdAt,
                updatedAtColumn <- category.updatedAt
            ))
            logger.info("Inserted expense category: \(category.id)")
            return true
        } catch {
            logger.error("Failed to insert expense category: \(error)")
            return false
        }
    }

    func update(_ category: ExpenseCategory) -> Bool {
        let record = table.filter(idColumn == category.id.uuidString)
        do {
            try db.run(record.update(
                nameColumn <- category.name,
                budgetLimitColumn <- category.budgetLimit.map { "\($0)" },
                budgetCurrencyColumn <- category.budgetCurrency?.rawValue,
                colorColumn <- category.color,
                sortOrderColumn <- category.sortOrder,
                updatedAtColumn <- Date()
            ))
            logger.info("Updated expense category: \(category.id)")
            return true
        } catch {
            logger.error("Failed to update expense category: \(error)")
            return false
        }
    }

    func delete(id: UUID) -> Bool {
        let record = table.filter(idColumn == id.uuidString)
        do {
            try db.run(record.delete())
            logger.info("Deleted expense category: \(id)")
            return true
        } catch {
            logger.error("Failed to delete expense category: \(error)")
            return false
        }
    }

    func deleteByProjectId(projectId: UUID) -> Bool {
        let records = table.filter(projectIdColumn == projectId.uuidString)
        do {
            try db.run(records.delete())
            logger.info("Deleted categories for project: \(projectId)")
            return true
        } catch {
            logger.error("Failed to delete categories for project: \(error)")
            return false
        }
    }

    // MARK: - Row Mapping

    private func mapRow(_ row: Row) -> ExpenseCategory? {
        guard let id = UUID(uuidString: row[idColumn]),
              let projectId = UUID(uuidString: row[projectIdColumn])
        else { return nil }

        let budgetLimit: Decimal? = row[budgetLimitColumn].flatMap { Decimal(string: $0) }
        let budgetCurrency: Currency? = row[budgetCurrencyColumn].flatMap { Currency(rawValue: $0) }

        return ExpenseCategory(
            id: id,
            projectId: projectId,
            name: row[nameColumn],
            budgetLimit: budgetLimit,
            budgetCurrency: budgetCurrency,
            color: row[colorColumn],
            sortOrder: row[sortOrderColumn],
            createdAt: row[createdAtColumn],
            updatedAt: row[updatedAtColumn]
        )
    }
}
