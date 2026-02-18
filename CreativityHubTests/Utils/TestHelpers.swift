import Foundation
@testable import CreativityHub

func createTestProject(
    id: UUID = UUID(),
    name: String = "Test Project",
    status: ProjectStatus = .active,
    budget: Decimal? = nil,
    budgetCurrency: Currency? = nil,
    isPinned: Bool = false
) -> Project {
    Project(
        id: id,
        name: name,
        status: status,
        budget: budget,
        budgetCurrency: budgetCurrency,
        isPinned: isPinned
    )
}

func createTestNote(
    id: UUID = UUID(),
    projectId: UUID,
    title: String = "Test Note",
    content: String = "Test content",
    isPinned: Bool = false,
    sortOrder: Int = 0
) -> Note {
    Note(
        id: id,
        projectId: projectId,
        title: title,
        content: content,
        isPinned: isPinned,
        sortOrder: sortOrder
    )
}

func createTestReminder(
    id: UUID = UUID(),
    projectId: UUID,
    title: String = "Test Reminder",
    notes: String? = nil,
    dueDate: Date? = nil,
    isCompleted: Bool = false,
    priority: ItemPriority = .none
) -> Reminder {
    Reminder(
        id: id,
        projectId: projectId,
        title: title,
        notes: notes,
        dueDate: dueDate,
        isCompleted: isCompleted,
        priority: priority
    )
}

func createTestChecklist(
    id: UUID = UUID(),
    projectId: UUID,
    name: String = "Test Checklist",
    sortOrder: Int = 0
) -> Checklist {
    Checklist(
        projectId: projectId,
        name: name,
        sortOrder: sortOrder
    )
}

func createTestExpenseCategory(
    id: UUID = UUID(),
    projectId: UUID,
    name: String = "Test Category",
    color: String = "blue",
    sortOrder: Int = 0
) -> ExpenseCategory {
    ExpenseCategory(
        id: id,
        projectId: projectId,
        name: name,
        color: color,
        sortOrder: sortOrder
    )
}
