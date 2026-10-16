import Foundation
import SQLite
import Testing
@testable import CreativityHub

struct ProjectDefaultCurrencyMigrationTests {
    @Test func upgradePreservesProjectAndExpense() throws {
        let database = try legacyDatabase()
        let projectId = UUID()
        let date = Date(timeIntervalSince1970: 1_750_000_000)
        try database.run(Table("projects").insert(
            SQLite.Expression<String>("id") <- projectId.uuidString,
            SQLite.Expression<String>("name") <- "Legacy Project",
            SQLite.Expression<String?>("budget") <- "100",
            SQLite.Expression<String?>("budget_currency") <- Currency.eur.rawValue,
            SQLite.Expression<Date>("created_at") <- date,
            SQLite.Expression<Date>("updated_at") <- date
        ))
        let expense = Expense(projectId: projectId, amount: Decimal(25), currency: .rub)
        let expenses = ExpenseRepository(db: database)
        #expect(expenses.insert(expense))

        try Migration20261016ProjectCurrency(db: database).execute()

        let project = try #require(ProjectRepository(db: database).fetchById(id: projectId))
        #expect(project.defaultExpenseCurrency == nil)
        #expect(project.budget == Decimal(100))
        #expect(project.budgetCurrency == .eur)
        #expect(project.createdAt == date)
        #expect(project.updatedAt == date)
        #expect(project.resolvedExpenseCurrency(fallback: .kzt) == .kzt)
        let savedExpense = try #require(expenses.fetchById(id: expense.id))
        #expect(savedExpense.amount == expense.amount)
        #expect(savedExpense.currency == .rub)
    }

    @Test func migrationCanBeRetriedWithoutDataLoss() throws {
        let database = try legacyDatabase()
        let migration = Migration20261016ProjectCurrency(db: database)
        try migration.execute()
        let projects = ProjectRepository(db: database)
        let project = Project(name: "Saved Currency", defaultExpenseCurrency: .kzt)
        #expect(projects.insert(project))

        try migration.execute()

        #expect(projects.fetchById(id: project.id)?.defaultExpenseCurrency == .kzt)
        let columns = try database.prepare("PRAGMA table_info(projects)")
        #expect(columns.filter { $0[1] as? String == "default_expense_currency" }.count == 1)
    }

    @Test func emptyDatabaseAcceptsProjectCurrency() throws {
        let database = try legacyDatabase()
        try Migration20261016ProjectCurrency(db: database).execute()
        let projects = ProjectRepository(db: database)
        let project = Project(name: "New Project", defaultExpenseCurrency: .eur)

        #expect(projects.insert(project))
        #expect(projects.fetchById(id: project.id)?.defaultExpenseCurrency == .eur)
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
        return database
    }
}
