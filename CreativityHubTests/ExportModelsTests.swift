import Testing
import Foundation
@testable import CreativityHub

struct ExportModelsTests {
    @Test func projectCurrencySurvivesJSONRoundTrip() throws {
        let project = createTestProject(name: "Project Currency")
        let data = try JSONEncoder().encode(project)
        var json = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
        json["defaultExpenseCurrency"] = Currency.kzt.rawValue

        let decoded = try JSONDecoder().decode(
            Project.self,
            from: JSONSerialization.data(withJSONObject: json)
        )
        let encoded = try JSONEncoder().encode(decoded)
        let result = try #require(JSONSerialization.jsonObject(with: encoded) as? [String: Any])

        #expect(result["defaultExpenseCurrency"] as? String == Currency.kzt.rawValue)
    }

    @Test func legacyProjectInheritsAppCurrency() throws {
        let original = Project(name: "Legacy Project", defaultExpenseCurrency: .eur)
        let data = try JSONEncoder().encode(original)
        var json = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
        json.removeValue(forKey: "defaultExpenseCurrency")

        let decoded = try JSONDecoder().decode(
            Project.self,
            from: JSONSerialization.data(withJSONObject: json)
        )

        #expect(decoded.defaultExpenseCurrency == nil)
        #expect(decoded.resolvedExpenseCurrency(fallback: .kzt) == .kzt)
    }

    @Test(arguments: [Currency.kzt, Currency.eur, nil])
    func optionalProjectCurrencyRoundTrips(currency: Currency?) throws {
        let project = Project(name: "Currency Project", defaultExpenseCurrency: currency)

        let decoded = try JSONDecoder().decode(Project.self, from: JSONEncoder().encode(project))

        #expect(decoded.defaultExpenseCurrency == currency)
    }

    @Test func exportRestoresProjectCurrencies() throws {
        let projects = [
            Project(name: "Tenge", budget: Decimal(100), budgetCurrency: .eur, defaultExpenseCurrency: .kzt),
            Project(name: "Euro", defaultExpenseCurrency: .eur),
            Project(name: "Inherited")
        ]
        let expense = Expense(projectId: projects[0].id, amount: Decimal(25), currency: .rub)
        let export = ExportData(
            metadata: ExportMetadata(appVersion: "2026.1.2", deviceName: "Test", databaseSchemaVersion: 8),
            userSettings: ExportUserSettings(currency: .gbp, language: .en, colorScheme: .system),
            projects: projects,
            expenses: [expense]
        )
        let decoded = try JSONDecoder().decode(ExportData.self, from: JSONEncoder().encode(export))
        let helper = try TestDatabaseHelper()
        #expect(helper.userSettingsRepository.upsertCurrency(decoded.userSettings.preferredCurrency))
        for project in try #require(decoded.projects) {
            #expect(helper.projectRepository.insert(project))
        }
        for expense in try #require(decoded.expenses) {
            #expect(helper.expenseRepository.insert(expense))
        }

        let restored = try #require(helper.projectRepository.fetchById(id: projects[0].id))
        #expect(restored.defaultExpenseCurrency == .kzt)
        #expect(restored.budget == Decimal(100))
        #expect(restored.budgetCurrency == .eur)
        #expect(helper.projectRepository.fetchById(id: projects[1].id)?.defaultExpenseCurrency == .eur)
        let inherited = try #require(helper.projectRepository.fetchById(id: projects[2].id))
        #expect(inherited.defaultExpenseCurrency == nil)
        #expect(inherited.resolvedExpenseCurrency(fallback: helper.userSettingsRepository.fetchCurrency()) == .gbp)
        let savedExpense = try #require(helper.expenseRepository.fetchById(id: expense.id))
        #expect(savedExpense.amount == expense.amount)
        #expect(savedExpense.currency == .rub)
    }

    @Test func exportData_encodesAndDecodes() throws {
        let project = createTestProject(name: "Export Test")
        let note = createTestNote(projectId: project.id, title: "Test Note")
        let reminder = createTestReminder(projectId: project.id, title: "Test Reminder")

        let exportData = ExportData(
            metadata: ExportMetadata(
                appVersion: "1.0.0",
                deviceName: "Test Device",
                databaseSchemaVersion: 4
            ),
            userSettings: ExportUserSettings(
                currency: .usd,
                language: .en,
                colorScheme: .system
            ),
            projects: [project],
            notes: [note],
            reminders: [reminder]
        )

        let data = try JSONEncoder().encode(exportData)
        let decoded = try JSONDecoder().decode(ExportData.self, from: data)

        #expect(decoded.metadata.appVersion == "1.0.0")
        #expect(decoded.metadata.deviceName == "Test Device")
        #expect(decoded.metadata.databaseSchemaVersion == 4)
        #expect(decoded.userSettings.preferredCurrency == "$")
        #expect(decoded.userSettings.preferredLanguage == "en")
        #expect(decoded.projects?.count == 1)
        #expect(decoded.projects?.first?.name == "Export Test")
        #expect(decoded.notes?.count == 1)
        #expect(decoded.reminders?.count == 1)
    }

    @Test func exportData_handlesNilCollections() throws {
        let exportData = ExportData(
            metadata: ExportMetadata(
                appVersion: "1.0.0",
                deviceName: "Test",
                databaseSchemaVersion: 4
            ),
            userSettings: ExportUserSettings(
                currency: .eur,
                language: .ru,
                colorScheme: .dark
            )
        )

        let data = try JSONEncoder().encode(exportData)
        let decoded = try JSONDecoder().decode(ExportData.self, from: data)

        #expect(decoded.projects == nil)
        #expect(decoded.checklists == nil)
        #expect(decoded.notes == nil)
        #expect(decoded.reminders == nil)
        #expect(decoded.userSettings.preferredCurrency == "€")
        #expect(decoded.userSettings.preferredLanguage == "ru")
    }

    @Test func ideaTagLink_encodesAndDecodes() throws {
        let ideaId = UUID()
        let tagId = UUID()
        let link = IdeaTagLink(ideaId: ideaId, tagId: tagId)

        let data = try JSONEncoder().encode(link)
        let decoded = try JSONDecoder().decode(IdeaTagLink.self, from: data)

        #expect(decoded.ideaId == ideaId)
        #expect(decoded.tagId == tagId)
    }

    @Test func project_encodesAndDecodes_withBudget() throws {
        let project = Project(
            name: "Budget Project",
            budget: Decimal(500),
            budgetCurrency: .usd
        )

        let data = try JSONEncoder().encode(project)
        let decoded = try JSONDecoder().decode(Project.self, from: data)

        #expect(decoded.name == "Budget Project")
        #expect(decoded.budget == Decimal(500))
        #expect(decoded.budgetCurrency == .usd)
        #expect(decoded.hasBudget == true)
    }

    @Test func project_computedProperties_workCorrectly() {
        let active = createTestProject(status: .active)
        #expect(active.isActive == true)
        #expect(active.isCompleted == false)
        #expect(active.isArchived == false)

        let completed = createTestProject(status: .completed)
        #expect(completed.isCompleted == true)

        let withBudget = createTestProject(budget: Decimal(100), budgetCurrency: .eur)
        #expect(withBudget.hasBudget == true)

        let noBudget = createTestProject()
        #expect(noBudget.hasBudget == false)
    }

    @Test func note_computedProperties_workCorrectly() {
        let projectId = UUID()

        let shortNote = createTestNote(projectId: projectId, content: "Short")
        #expect(shortNote.contentPreview == "Short")
        #expect(shortNote.hasContent == true)
        #expect(shortNote.isEmpty == false)

        let emptyNote = createTestNote(projectId: projectId, title: "", content: "")
        #expect(emptyNote.isEmpty == true)
        #expect(emptyNote.hasContent == false)

        let longContent = String(repeating: "A", count: 150)
        let longNote = createTestNote(projectId: projectId, content: longContent)
        #expect(longNote.contentPreview.count == 103) // 100 chars + "..."
    }

    @Test func reminder_isOverdue_whenPastDueAndNotCompleted() {
        let projectId = UUID()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!

        let overdue = createTestReminder(
            projectId: projectId,
            title: "Overdue",
            dueDate: yesterday,
            isCompleted: false
        )
        #expect(overdue.isOverdue == true)

        let completedOverdue = createTestReminder(
            projectId: projectId,
            title: "Done",
            dueDate: yesterday,
            isCompleted: true
        )
        #expect(completedOverdue.isOverdue == false)

        let noDueDate = createTestReminder(
            projectId: projectId,
            title: "No date"
        )
        #expect(noDueDate.isOverdue == false)
    }
}
