import SQLite

final class Migration20261016ProjectCurrency {
    private let database: Connection

    init(db database: Connection) {
        self.database = database
    }

    func execute() throws {
        let columnName = "default_expense_currency"
        let columns = try database.prepare("PRAGMA table_info(projects)")
        guard !columns.contains(where: { $0[1] as? String == columnName }) else { return }

        try database.run(Table("projects").addColumn(Expression<String?>(columnName), defaultValue: nil))
    }
}
