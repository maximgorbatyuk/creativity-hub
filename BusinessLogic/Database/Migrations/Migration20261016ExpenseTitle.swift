import SQLite

final class Migration20261016ExpenseTitle {
    private let database: Connection

    init(db database: Connection) {
        self.database = database
    }

    func execute() throws {
        try database.transaction {
            let rows = try database.prepare("PRAGMA table_info(expenses)")
            var columns = Set(rows.compactMap { $0[1] as? String })
            guard columns.contains("title") || columns.contains("vendor") else {
                throw RuntimeError("Expense table has neither title nor vendor columns")
            }

            if !columns.contains("title") {
                try database.run("ALTER TABLE expenses RENAME COLUMN vendor TO title")
                columns.remove("vendor")
            }
            if !columns.contains("vendor") {
                try database.run(Table("expenses").addColumn(Expression<String?>("vendor"), defaultValue: nil))
            }
        }
    }
}
