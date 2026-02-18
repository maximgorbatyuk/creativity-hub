import Foundation
import os

enum SearchResultSection: String, CaseIterable, Identifiable {
    case projects
    case ideas
    case notes
    case reminders
    case expenses
    case checklistItems

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .projects: return L("search.section.projects")
        case .ideas: return L("search.section.ideas")
        case .notes: return L("search.section.notes")
        case .reminders: return L("search.section.reminders")
        case .expenses: return L("search.section.expenses")
        case .checklistItems: return L("search.section.checklist_items")
        }
    }

    var icon: String {
        switch self {
        case .projects: return "folder.fill"
        case .ideas: return "lightbulb.fill"
        case .notes: return "note.text"
        case .reminders: return "bell.fill"
        case .expenses: return "creditcard.fill"
        case .checklistItems: return "checkmark.circle"
        }
    }
}

@MainActor
@Observable
final class SearchViewModel {

    // MARK: - State

    var projects: [Project] = []
    var ideas: [Idea] = []
    var notes: [Note] = []
    var reminders: [Reminder] = []
    var expenses: [Expense] = []
    var checklistItems: [ChecklistItem] = []
    var isSearching = false

    // MARK: - Private

    private let projectRepository: ProjectRepository?
    private let ideaRepository: IdeaRepository?
    private let noteRepository: NoteRepository?
    private let reminderRepository: ReminderRepository?
    private let expenseRepository: ExpenseRepository?
    private let checklistItemRepository: ChecklistItemRepository?
    private let logger: Logger

    // MARK: - Init

    init(databaseManager: DatabaseManager = .shared) {
        self.projectRepository = databaseManager.projectRepository
        self.ideaRepository = databaseManager.ideaRepository
        self.noteRepository = databaseManager.noteRepository
        self.reminderRepository = databaseManager.reminderRepository
        self.expenseRepository = databaseManager.expenseRepository
        self.checklistItemRepository = databaseManager.checklistItemRepository
        self.logger = Logger(
            subsystem: Bundle.main.bundleIdentifier ?? "-",
            category: "SearchViewModel"
        )
    }

    // MARK: - Public

    func search(query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2 else {
            clearResults()
            return
        }

        isSearching = true
        projects = projectRepository?.search(query: trimmed) ?? []
        ideas = ideaRepository?.search(query: trimmed) ?? []
        notes = noteRepository?.search(query: trimmed) ?? []
        reminders = reminderRepository?.search(query: trimmed) ?? []
        expenses = expenseRepository?.search(query: trimmed) ?? []
        checklistItems = checklistItemRepository?.search(query: trimmed) ?? []
        isSearching = false
    }

    func clearResults() {
        projects = []
        ideas = []
        notes = []
        reminders = []
        expenses = []
        checklistItems = []
    }

    // MARK: - Computed

    var hasResults: Bool {
        !projects.isEmpty || !ideas.isEmpty || !notes.isEmpty ||
        !reminders.isEmpty || !expenses.isEmpty || !checklistItems.isEmpty
    }

    var totalResultCount: Int {
        projects.count + ideas.count + notes.count +
        reminders.count + expenses.count + checklistItems.count
    }

    var visibleSections: [SearchResultSection] {
        var sections: [SearchResultSection] = []
        if !projects.isEmpty { sections.append(.projects) }
        if !ideas.isEmpty { sections.append(.ideas) }
        if !notes.isEmpty { sections.append(.notes) }
        if !reminders.isEmpty { sections.append(.reminders) }
        if !expenses.isEmpty { sections.append(.expenses) }
        if !checklistItems.isEmpty { sections.append(.checklistItems) }
        return sections
    }
}
