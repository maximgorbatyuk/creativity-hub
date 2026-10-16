import Foundation
import SQLite
import Testing
@testable import CreativityHub

struct ExpenseTitleVendorMigrationTests {
    @Test(arguments: [nil, "", "  Материалы для макета 🧶  "] as [String?])
    func upgradePreservesEveryField(vendor: String?) throws {
        let database = try legacyDatabase()
        let project = Project(name: "Legacy", defaultExpenseCurrency: .kzt)
        #expect(ProjectRepository(db: database).insert(project))
        let expense = Expense(
            projectId: project.id,
            categoryId: UUID(),
            amount: try #require(Decimal(string: "1234567890.123456789")),
            currency: .eur,
            date: Date(timeIntervalSince1970: 1_750_000_000),
            vendor: vendor,
            status: .paid,
            receiptImagePath: "receipts/photo.jpg",
            notes: "Original notes",
            linkedChecklistItemId: UUID(),
            createdAt: Date(timeIntervalSince1970: 1_750_000_001),
            updatedAt: Date(timeIntervalSince1970: 1_750_000_002)
        )
        try insertLegacyExpense(expense, into: database)

        try Migration20261016ExpenseTitle(db: database).execute()

        var expected = expense
        expected.title = vendor
        expected.vendor = nil
        let repository = ExpenseRepository(db: database)
        #expect(repository.fetchById(id: expense.id) == expected)
        #expect(repository.fetchAll().count == 1)
        #expect(ProjectRepository(db: database).fetchById(id: project.id)?.defaultExpenseCurrency == .kzt)
    }

    @Test func retryKeepsNewVendorAndTitle() throws {
        let database = try legacyDatabase()
        let migration = Migration20261016ExpenseTitle(db: database)
        try migration.execute()
        let repository = ExpenseRepository(db: database)
        let expense = Expense(
            projectId: UUID(), amount: Decimal(25), currency: .usd,
            title: "Materials", vendor: "New Supplier"
        )
        #expect(repository.insert(expense))

        try migration.execute()

        let saved = try #require(repository.fetchById(id: expense.id))
        #expect(saved.title == "Materials")
        #expect(saved.vendor == "New Supplier")
        #expect(repository.fetchAll().count == 1)
    }

    @Test func completesSchemaWithRenamedColumn() throws {
        let database = try legacyDatabase()
        let expense = Expense(projectId: UUID(), amount: Decimal(25), currency: .usd, vendor: "Legacy title")
        try insertLegacyExpense(expense, into: database)
        try database.run("ALTER TABLE expenses RENAME COLUMN vendor TO title")

        try Migration20261016ExpenseTitle(db: database).execute()

        let saved = try #require(ExpenseRepository(db: database).fetchById(id: expense.id))
        #expect(saved.title == "Legacy title")
        #expect(saved.vendor == nil)
    }

    @Test func invalidSchemaDoesNotCreateColumns() throws {
        let database = try Connection(.inMemory)
        try database.run("CREATE TABLE expenses (id TEXT)")

        #expect(throws: RuntimeError.self) {
            try Migration20261016ExpenseTitle(db: database).execute()
        }

        let columns = try database.prepare("PRAGMA table_info(expenses)")
        #expect(columns.compactMap { $0[1] as? String } == ["id"])
    }

    private func legacyDatabase() throws -> Connection {
        let database = try Connection(.inMemory)
        UserSettingsRepository(db: database).createTable()
        try Migration_20260217_InitialSchema(db: database).execute()
        try Migration_20260218_AddDocumentsTable(db: database).execute()
        try Migration_20260218_AddRemindersTable(db: database).execute()
        try Migration_20260220_DocumentFilePath(db: database).execute()
        try Migration_20260220_AddWorkLogsTable(db: database).execute()
        try Migration_20260221_AddActivityLogsTable(db: database).execute()
        try Migration20261016ProjectCurrency(db: database).execute()
        return database
    }

    private func insertLegacyExpense(_ expense: Expense, into database: Connection) throws {
        try database.run(Table("expenses").insert(
            SQLite.Expression<String>("id") <- expense.id.uuidString,
            SQLite.Expression<String>("project_id") <- expense.projectId.uuidString,
            SQLite.Expression<String?>("category_id") <- expense.categoryId?.uuidString,
            SQLite.Expression<String>("amount") <- "\(expense.amount)",
            SQLite.Expression<String>("currency") <- expense.currency.rawValue,
            SQLite.Expression<Date>("date") <- expense.date,
            SQLite.Expression<String?>("vendor") <- expense.vendor,
            SQLite.Expression<String>("status") <- expense.status.rawValue,
            SQLite.Expression<String?>("receipt_image_path") <- expense.receiptImagePath,
            SQLite.Expression<String?>("notes") <- expense.notes,
            SQLite.Expression<String?>("linked_checklist_item_id") <- expense.linkedChecklistItemId?.uuidString,
            SQLite.Expression<Date>("created_at") <- expense.createdAt,
            SQLite.Expression<Date>("updated_at") <- expense.updatedAt
        ))
    }
}
