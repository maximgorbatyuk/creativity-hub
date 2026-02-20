import Foundation
import os

enum ExpenseFilter: Equatable {
    case all
    case status(ExpenseStatus)
    case category(ExpenseCategory)

    var displayName: String {
        switch self {
        case .all: return L("expense.filter.all")
        case .status(let status): return status.displayName
        case .category(let category): return category.name
        }
    }
}

@MainActor
@Observable
final class ExpensesListViewModel {

    // MARK: - State

    var expenses: [Expense] = []
    var filteredExpenses: [Expense] = []
    var categories: [ExpenseCategory] = []
    var selectedFilter: ExpenseFilter = .all {
        didSet { applyFilter() }
    }
    var isLoading = false

    var showAddSheet = false
    var expenseToEdit: Expense?
    var showCategorySheet = false

    let projectId: UUID

    // MARK: - Private

    private let expenseRepository: ExpenseRepository?
    private let categoryRepository: ExpenseCategoryRepository?
    private let projectRepository: ProjectRepository?
    private let userSettingsRepository: UserSettingsRepository?
    private let logger: Logger

    // MARK: - Init

    init(projectId: UUID, databaseManager: DatabaseManager = .shared) {
        self.projectId = projectId
        self.expenseRepository = databaseManager.expenseRepository
        self.categoryRepository = databaseManager.expenseCategoryRepository
        self.projectRepository = databaseManager.projectRepository
        self.userSettingsRepository = databaseManager.userSettingsRepository
        self.logger = Logger(
            subsystem: Bundle.main.bundleIdentifier ?? "-",
            category: "ExpensesListViewModel"
        )
    }

    // MARK: - Public

    func loadData() {
        isLoading = true
        expenses = expenseRepository?.fetchByProjectId(projectId: projectId) ?? []
        categories = categoryRepository?.fetchByProjectId(projectId: projectId) ?? []
        applyFilter()
        isLoading = false
    }

    var defaultCurrency: Currency {
        userSettingsRepository?.fetchCurrency() ?? .usd
    }

    func addExpense(_ expense: Expense) {
        guard expenseRepository?.insert(expense) == true else {
            logger.error("Failed to insert expense")
            return
        }
        projectRepository?.touchUpdatedAt(id: projectId)
        logger.info("Added expense \(expense.id)")
        loadData()
    }

    func updateExpense(_ expense: Expense) {
        guard expenseRepository?.update(expense) == true else {
            logger.error("Failed to update expense \(expense.id)")
            return
        }
        projectRepository?.touchUpdatedAt(id: projectId)
        logger.info("Updated expense \(expense.id)")
        loadData()
    }

    func deleteExpense(_ expense: Expense) {
        guard expenseRepository?.delete(id: expense.id) == true else {
            logger.error("Failed to delete expense \(expense.id)")
            return
        }
        projectRepository?.touchUpdatedAt(id: projectId)
        logger.info("Deleted expense \(expense.id)")
        loadData()
    }

    // MARK: - Categories

    func addCategory(_ category: ExpenseCategory) {
        guard categoryRepository?.insert(category) == true else {
            logger.error("Failed to insert category")
            return
        }
        logger.info("Added category \(category.id)")
        loadData()
    }

    func updateCategory(_ category: ExpenseCategory) {
        guard categoryRepository?.update(category) == true else {
            logger.error("Failed to update category \(category.id)")
            return
        }
        logger.info("Updated category \(category.id)")
        loadData()
    }

    func deleteCategory(_ category: ExpenseCategory) {
        guard categoryRepository?.delete(id: category.id) == true else {
            logger.error("Failed to delete category \(category.id)")
            return
        }
        logger.info("Deleted category \(category.id)")
        loadData()
    }

    func categoryName(for expense: Expense) -> String? {
        guard let categoryId = expense.categoryId else { return nil }
        return categories.first { $0.id == categoryId }?.name
    }

    // MARK: - Statistics

    var totalByCurrency: [Currency: Decimal] {
        expenseRepository?.calculateTotalByProjectId(projectId: projectId) ?? [:]
    }

    var formattedTotal: String {
        let sorted = totalByCurrency
            .filter { $0.value > 0 }
            .sorted { $0.key.shortName < $1.key.shortName }
        if sorted.isEmpty { return "" }
        return sorted
            .map { "\($0.key.rawValue)\(formatAmount($0.value))" }
            .joined(separator: " • ")
    }

    private func formatAmount(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        return formatter.string(from: value as NSDecimalNumber) ?? "\(value)"
    }

    // MARK: - Private

    private func applyFilter() {
        switch selectedFilter {
        case .all:
            filteredExpenses = expenses
        case .status(let status):
            filteredExpenses = expenses.filter { $0.status == status }
        case .category(let category):
            filteredExpenses = expenses.filter { $0.categoryId == category.id }
        }
    }
}
