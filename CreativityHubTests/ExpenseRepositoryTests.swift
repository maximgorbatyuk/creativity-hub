import Foundation
import Testing
@testable import CreativityHub

struct ExpenseRepositoryTests {
    @Test func fieldsSurviveAllExpenseQueries() throws {
        let helper = try TestDatabaseHelper()
        let project = createTestProject()
        let category = createTestExpenseCategory(projectId: project.id)
        #expect(helper.projectRepository.insert(project))
        #expect(helper.expenseCategoryRepository.insert(category))
        let expense = Expense(
            projectId: project.id,
            categoryId: category.id,
            amount: Decimal(25),
            currency: .kzt,
            title: "Materials",
            vendor: "Supplier"
        )
        #expect(helper.expenseRepository.insert(expense))

        let results = [
            helper.expenseRepository.fetchById(id: expense.id),
            helper.expenseRepository.fetchAll().first,
            helper.expenseRepository.fetchByProjectId(projectId: project.id).first,
            helper.expenseRepository.fetchByCategoryId(categoryId: category.id).first
        ]
        for result in results {
            let saved = try #require(result)
            #expect(saved.title == "Materials")
            #expect(saved.vendor == "Supplier")
            #expect(saved.amount == expense.amount)
            #expect(saved.currency == expense.currency)
        }
    }

    @Test func fieldsCanBeUpdatedIndependently() throws {
        let helper = try TestDatabaseHelper()
        var expense = Expense(
            projectId: UUID(), amount: Decimal(25), currency: .eur,
            title: "Original", vendor: "Supplier"
        )
        #expect(helper.expenseRepository.insert(expense))

        expense.title = "Updated"
        #expect(helper.expenseRepository.update(expense))
        #expect(helper.expenseRepository.fetchById(id: expense.id)?.vendor == "Supplier")

        expense.vendor = nil
        #expect(helper.expenseRepository.update(expense))
        let cleared = try #require(helper.expenseRepository.fetchById(id: expense.id))
        #expect(cleared.title == "Updated")
        #expect(cleared.vendor == nil)

        expense.title = nil
        expense.vendor = "Another Supplier"
        #expect(helper.expenseRepository.update(expense))
        let untitled = try #require(helper.expenseRepository.fetchById(id: expense.id))
        #expect(untitled.title == nil)
        #expect(untitled.vendor == "Another Supplier")
    }

    @Test(arguments: ["Materials", "Supplier", "Reference"])
    func searchIncludesBothFieldsAndNotes(query: String) throws {
        let helper = try TestDatabaseHelper()
        let expense = Expense(
            projectId: UUID(), amount: Decimal(25), currency: .usd,
            title: "Materials", vendor: "Supplier", notes: "Reference"
        )
        #expect(helper.expenseRepository.insert(expense))

        #expect(helper.expenseRepository.search(query: query).map(\.id) == [expense.id])
    }

    @Test(arguments: [nil, "", " \n "] as [String?])
    func legacyTitleRemainsNullable(title: String?) throws {
        let helper = try TestDatabaseHelper()
        let expense = Expense(projectId: UUID(), amount: Decimal(25), currency: .usd, title: title)
        #expect(helper.expenseRepository.insert(expense))

        let saved = try #require(helper.expenseRepository.fetchById(id: expense.id))
        #expect(saved.title == title)
        #expect(saved.vendor == nil)
        #expect(saved.displayTitle == L("expense.detail.title"))
    }
}
