import Foundation
import os

@MainActor
@Observable
final class TodayViewModel {

    // MARK: - State

    var activeProjects: [Project] = []
    var overdueChecklistItems: [ChecklistItem] = []
    var upcomingReminders: [Reminder] = []
    var overdueReminders: [Reminder] = []
    var isLoading = false

    // MARK: - Private

    private let projectRepository: ProjectRepository?
    private let checklistItemRepository: ChecklistItemRepository?
    private let reminderRepository: ReminderRepository?
    private let logger: Logger

    // MARK: - Init

    init(databaseManager: DatabaseManager = .shared) {
        self.projectRepository = databaseManager.projectRepository
        self.checklistItemRepository = databaseManager.checklistItemRepository
        self.reminderRepository = databaseManager.reminderRepository
        self.logger = Logger(
            subsystem: Bundle.main.bundleIdentifier ?? "-",
            category: "TodayViewModel"
        )
    }

    // MARK: - Public

    func loadData() {
        isLoading = true
        activeProjects = projectRepository?.fetchByStatus(.active) ?? []
        overdueChecklistItems = checklistItemRepository?.fetchOverdueItems() ?? []
        upcomingReminders = reminderRepository?.fetchUpcoming(limit: 5) ?? []
        overdueReminders = reminderRepository?.fetchOverdue() ?? []
        isLoading = false
    }

    // MARK: - Statistics

    var activeProjectCount: Int { activeProjects.count }
    var overdueItemCount: Int { overdueChecklistItems.count }
    var overdueReminderCount: Int { overdueReminders.count }

    var hasOverdueItems: Bool {
        !overdueChecklistItems.isEmpty || !overdueReminders.isEmpty
    }

    var hasUpcomingReminders: Bool {
        !upcomingReminders.isEmpty
    }

    // MARK: - Helpers

    func projectName(for item: ChecklistItem) -> String? {
        guard let projects = projectRepository?.fetchAll() else { return nil }
        // ChecklistItem → Checklist → Project is indirect; show item name only
        return nil
    }

    func projectName(for reminder: Reminder) -> String? {
        projectRepository?.fetchById(id: reminder.projectId)?.name
    }
}
