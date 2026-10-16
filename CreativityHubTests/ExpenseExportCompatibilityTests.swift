import Foundation
import Testing
@testable import CreativityHub

struct ExpenseExportCompatibilityTests {
    @Test func titleSurvivesJSONRoundTrip() throws {
        let expense = Expense(projectId: UUID(), amount: Decimal(25), currency: .kzt, vendor: "Supplier")
        let data = try JSONEncoder().encode(expense)
        var json = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
        json["title"] = "Materials"

        let decoded = try JSONDecoder().decode(
            Expense.self,
            from: JSONSerialization.data(withJSONObject: json)
        )
        let encoded = try JSONEncoder().encode(decoded)
        let result = try #require(JSONSerialization.jsonObject(with: encoded) as? [String: Any])

        #expect(result["title"] as? String == "Materials")
        #expect(result["vendor"] as? String == "Supplier")
    }

    @Test(arguments: [2, 4, 8])
    func legacyVendorBecomesTitle(version: Int) throws {
        let source = exportData(
            version: version,
            expense: Expense(projectId: UUID(), amount: Decimal(25), currency: .usd, vendor: "  Материалы 🧶  ")
        )
        let decoded = try roundTrip(source)
        let imported = try #require(decoded.expensesForImport?.first)

        #expect(imported.title == "  Материалы 🧶  ")
        #expect(imported.vendor == nil)
        #expect(decoded.expenses?.first?.vendor == "  Материалы 🧶  ")
        #expect(try roundTrip(decoded).expensesForImport == decoded.expensesForImport)
    }

    @Test(arguments: [nil, ""] as [String?])
    func legacyEmptyValueIsPreserved(vendor: String?) throws {
        let source = exportData(
            version: 8,
            expense: Expense(projectId: UUID(), amount: Decimal(25), currency: .usd, vendor: vendor)
        )
        let decoded = try roundTrip(source)
        let imported = try #require(decoded.expensesForImport?.first)

        #expect(imported.title == vendor)
        #expect(imported.vendor == nil)
    }

    @Test(arguments: [9, 10])
    func newFormatKeepsFieldsSeparate(version: Int) throws {
        let expense = Expense(
            projectId: UUID(), amount: Decimal(25), currency: .eur,
            title: "Materials", vendor: "Supplier"
        )
        let decoded = try roundTrip(exportData(version: version, expense: expense))

        #expect(decoded.expensesForImport?.first == decoded.expenses?.first)
        #expect(decoded.expensesForImport?.first?.title == "Materials")
        #expect(decoded.expensesForImport?.first?.vendor == "Supplier")
    }

    @Test func newVendorDoesNotBecomeMissingTitle() throws {
        let expense = Expense(projectId: UUID(), amount: Decimal(25), currency: .usd, vendor: "Supplier")
        let decoded = try roundTrip(exportData(version: 9, expense: expense))
        let imported = try #require(decoded.expensesForImport?.first)

        #expect(imported.title == nil)
        #expect(imported.vendor == "Supplier")
    }

    @Test func legacyImportAndNewExportPreserveData() throws {
        let project = Project(name: "Legacy", defaultExpenseCurrency: .kzt)
        let expense = Expense(
            projectId: project.id,
            amount: try #require(Decimal(string: "1234567890.123456789")),
            currency: .eur,
            date: Date(timeIntervalSince1970: 1_750_000_000),
            vendor: "Legacy title",
            status: .paid,
            receiptImagePath: "receipts/image.jpg",
            notes: "Notes",
            createdAt: Date(timeIntervalSince1970: 1_750_000_001),
            updatedAt: Date(timeIntervalSince1970: 1_750_000_002)
        )
        let oldExport = exportData(version: 8, expense: expense)
        let oldDecoded = try roundTrip(oldExport)
        let helper = try TestDatabaseHelper()
        #expect(helper.projectRepository.insert(project))
        #expect(helper.expenseRepository.insert(try #require(oldDecoded.expensesForImport?.first)))
        let snapshot = try #require(helper.expenseRepository.fetchById(id: expense.id))
        let newExport = ExportData(
            metadata: ExportMetadata(appVersion: "2026.1.2", deviceName: "Test", databaseSchemaVersion: 9),
            userSettings: oldExport.userSettings,
            projects: helper.projectRepository.fetchAll(),
            expenses: helper.expenseRepository.fetchAll()
        )
        let newDecoded = try roundTrip(newExport)
        let restored = try TestDatabaseHelper()
        #expect(restored.projectRepository.insert(try #require(newDecoded.projects?.first)))
        #expect(restored.expenseRepository.insert(try #require(newDecoded.expensesForImport?.first)))

        let result = try #require(restored.expenseRepository.fetchById(id: expense.id))
        #expect(result == snapshot)
        #expect(result.title == "Legacy title")
        #expect(result.vendor == nil)
        #expect(result.amount == expense.amount)
        #expect(result.currency == expense.currency)
        #expect(restored.projectRepository.fetchById(id: project.id)?.defaultExpenseCurrency == .kzt)
    }

    private func exportData(version: Int, expense: Expense) -> ExportData {
        ExportData(
            metadata: ExportMetadata(appVersion: "2026.1.2", deviceName: "Test", databaseSchemaVersion: version),
            userSettings: ExportUserSettings(currency: .kzt, language: .en, colorScheme: .system),
            expenses: [expense]
        )
    }

    private func roundTrip(_ source: ExportData) throws -> ExportData {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(ExportData.self, from: encoder.encode(source))
    }
}
