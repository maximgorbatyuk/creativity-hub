import Foundation
import SQLite
import os

class ExpenseRepository {
    private let table = Table("expenses")

    private let idColumn = Expression<String>("id")
    private let projectIdColumn = Expression<String>("project_id")
    private let categoryIdColumn = Expression<String?>("category_id")
    private let amountColumn = Expression<String>("amount")
    private let currencyColumn = Expression<String>("currency")
    private let dateColumn = Expression<Date>("date")
    private let vendorColumn = Expression<String?>("vendor")
    private let statusColumn = Expression<String>("status")
    private let receiptImagePathColumn = Expression<String?>("receipt_image_path")
    private let notesColumn = Expression<String?>("notes")
    private let linkedChecklistItemIdColumn = Expression<String?>("linked_checklist_item_id")
    private let createdAtColumn = Expression<Date>("created_at")
    private let updatedAtColumn = Expression<Date>("updated_at")

    private let db: Connection
    private let logger: Logger

    init(db: Connection, logger: Logger? = nil) {
        self.db = db
        self.logger = logger ?? Logger(
            subsystem: Bundle.main.bundleIdentifier ?? "-",
            category: "ExpenseRepository"
        )
    }

    func fetchAll() -> [Expense] {
        var expenses: [Expense] = []
        do {
            for row in try db.prepare(table.order(dateColumn.desc)) {
                if let expense = mapRow(row) {
                    expenses.append(expense)
                }
            }
        } catch {
            logger.error("Failed to fetch all expenses: \(error)")
        }
        return expenses
    }

    func deleteAll() {
        do {
            try db.run(table.delete())
        } catch {
            logger.error("Failed to delete all expenses: \(error)")
        }
    }

    func fetchByProjectId(projectId: UUID) -> [Expense] {
        var expenses: [Expense] = []
        do {
            let query = table.filter(projectIdColumn == projectId.uuidString)
                .order(dateColumn.desc)
            for row in try db.prepare(query) {
                if let expense = mapRow(row) {
                    expenses.append(expense)
                }
            }
        } catch {
            logger.error("Failed to fetch expenses for project \(projectId): \(error)")
        }
        return expenses
    }

    func fetchById(id: UUID) -> Expense? {
        do {
            let query = table.filter(idColumn == id.uuidString)
            if let row = try db.pluck(query) {
                return mapRow(row)
            }
        } catch {
            logger.error("Failed to fetch expense by id \(id): \(error)")
        }
        return nil
    }

    func fetchByCategoryId(categoryId: UUID) -> [Expense] {
        var expenses: [Expense] = []
        do {
            let query = table.filter(categoryIdColumn == categoryId.uuidString)
                .order(dateColumn.desc)
            for row in try db.prepare(query) {
                if let expense = mapRow(row) {
                    expenses.append(expense)
                }
            }
        } catch {
            logger.error("Failed to fetch expenses for category \(categoryId): \(error)")
        }
        return expenses
    }

    func insert(_ expense: Expense) -> Bool {
        do {
            try db.run(table.insert(
                idColumn <- expense.id.uuidString,
                projectIdColumn <- expense.projectId.uuidString,
                categoryIdColumn <- expense.categoryId?.uuidString,
                amountColumn <- "\(expense.amount)",
                currencyColumn <- expense.currency.rawValue,
                dateColumn <- expense.date,
                vendorColumn <- expense.vendor,
                statusColumn <- expense.status.rawValue,
                receiptImagePathColumn <- expense.receiptImagePath,
                notesColumn <- expense.notes,
                linkedChecklistItemIdColumn <- expense.linkedChecklistItemId?.uuidString,
                createdAtColumn <- expense.createdAt,
                updatedAtColumn <- expense.updatedAt
            ))
            logger.info("Inserted expense: \(expense.id)")
            return true
        } catch {
            logger.error("Failed to insert expense: \(error)")
            return false
        }
    }

    func update(_ expense: Expense) -> Bool {
        let record = table.filter(idColumn == expense.id.uuidString)
        do {
            try db.run(record.update(
                categoryIdColumn <- expense.categoryId?.uuidString,
                amountColumn <- "\(expense.amount)",
                currencyColumn <- expense.currency.rawValue,
                dateColumn <- expense.date,
                vendorColumn <- expense.vendor,
                statusColumn <- expense.status.rawValue,
                receiptImagePathColumn <- expense.receiptImagePath,
                notesColumn <- expense.notes,
                linkedChecklistItemIdColumn <- expense.linkedChecklistItemId?.uuidString,
                updatedAtColumn <- Date()
            ))
            logger.info("Updated expense: \(expense.id)")
            return true
        } catch {
            logger.error("Failed to update expense: \(error)")
            return false
        }
    }

    func delete(id: UUID) -> Bool {
        let record = table.filter(idColumn == id.uuidString)
        do {
            try db.run(record.delete())
            logger.info("Deleted expense: \(id)")
            return true
        } catch {
            logger.error("Failed to delete expense: \(error)")
            return false
        }
    }

    func deleteByProjectId(projectId: UUID) -> Bool {
        let records = table.filter(projectIdColumn == projectId.uuidString)
        do {
            try db.run(records.delete())
            logger.info("Deleted expenses for project: \(projectId)")
            return true
        } catch {
            logger.error("Failed to delete expenses for project: \(error)")
            return false
        }
    }

    func calculateTotalByProjectId(projectId: UUID) -> [Currency: Decimal] {
        var totals: [Currency: Decimal] = [:]
        do {
            let query = table.filter(
                projectIdColumn == projectId.uuidString
                    && statusColumn == ExpenseStatus.paid.rawValue
            )
            for row in try db.prepare(query) {
                guard let amount = Decimal(string: row[amountColumn]),
                      let currency = Currency(rawValue: row[currencyColumn])
                else { continue }
                totals[currency, default: .zero] += amount
            }
        } catch {
            logger.error("Failed to calculate totals by currency for project: \(error)")
        }
        return totals
    }

    func totalByProjectId(projectId: UUID, status: ExpenseStatus? = nil) -> Decimal {
        var total: Decimal = 0
        do {
            var query = table.filter(projectIdColumn == projectId.uuidString)
            if let status = status {
                query = query.filter(statusColumn == status.rawValue)
            }
            for row in try db.prepare(query) {
                if let amount = Decimal(string: row[amountColumn]) {
                    total += amount
                }
            }
        } catch {
            logger.error("Failed to calculate total for project: \(error)")
        }
        return total
    }

    func countByProjectId(projectId: UUID) -> Int {
        do {
            return try db.scalar(table.filter(projectIdColumn == projectId.uuidString).count)
        } catch {
            logger.error("Failed to count expenses: \(error)")
            return 0
        }
    }

    func search(query searchQuery: String) -> [Expense] {
        var expenses: [Expense] = []
        let pattern = "%\(searchQuery)%"
        do {
            let query = table.filter(
                vendorColumn.like(pattern) || notesColumn.like(pattern)
            ).order(dateColumn.desc)
            for row in try db.prepare(query) {
                if let expense = mapRow(row) {
                    expenses.append(expense)
                }
            }
        } catch {
            logger.error("Failed to search expenses: \(error)")
        }
        return expenses
    }

    // MARK: - Row Mapping

    private func mapRow(_ row: Row) -> Expense? {
        guard let id = UUID(uuidString: row[idColumn]),
              let projectId = UUID(uuidString: row[projectIdColumn]),
              let amount = Decimal(string: row[amountColumn]),
              let currency = Currency(rawValue: row[currencyColumn])
        else { return nil }

        let categoryId = row[categoryIdColumn].flatMap { UUID(uuidString: $0) }
        let status = ExpenseStatus(rawValue: row[statusColumn]) ?? .planned
        let linkedItemId = row[linkedChecklistItemIdColumn].flatMap { UUID(uuidString: $0) }

        return Expense(
            id: id,
            projectId: projectId,
            categoryId: categoryId,
            amount: amount,
            currency: currency,
            date: row[dateColumn],
            vendor: row[vendorColumn],
            status: status,
            receiptImagePath: row[receiptImagePathColumn],
            notes: row[notesColumn],
            linkedChecklistItemId: linkedItemId,
            createdAt: row[createdAtColumn],
            updatedAt: row[updatedAtColumn]
        )
    }
}
