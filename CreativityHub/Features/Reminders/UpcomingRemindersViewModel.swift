import Foundation
import os

@MainActor
@Observable
final class UpcomingRemindersViewModel {

    // MARK: - State

    var reminders: [Reminder] = []
    var filteredReminders: [Reminder] = []
    var selectedFilter: ReminderFilter = .all {
        didSet { applyFilter() }
    }
    var isLoading = false
    var reminderToEdit: Reminder?

    // MARK: - Private

    private let reminderRepository: ReminderRepository?
    private let projectRepository: ProjectRepository?
    private let logger: Logger

    // MARK: - Init

    init(databaseManager: DatabaseManager = .shared) {
        self.reminderRepository = databaseManager.reminderRepository
        self.projectRepository = databaseManager.projectRepository
        self.logger = Logger(
            subsystem: Bundle.main.bundleIdentifier ?? "-",
            category: "UpcomingRemindersViewModel"
        )
    }

    // MARK: - Public

    func loadData() {
        isLoading = true
        reminders = reminderRepository?.fetchAll() ?? []
        applyFilter()
        isLoading = false
    }

    func updateReminder(_ reminder: Reminder) {
        guard reminderRepository?.update(reminder) == true else {
            logger.error("Failed to update reminder \(reminder.id)")
            return
        }
        projectRepository?.touchUpdatedAt(id: reminder.projectId)
        loadData()
    }

    func deleteReminder(_ reminder: Reminder) {
        guard reminderRepository?.delete(id: reminder.id) == true else {
            logger.error("Failed to delete reminder \(reminder.id)")
            return
        }
        projectRepository?.touchUpdatedAt(id: reminder.projectId)
        loadData()
    }

    func toggleCompleted(_ reminder: Reminder) {
        let newCompleted = !reminder.isCompleted
        guard reminderRepository?.toggleCompleted(id: reminder.id, isCompleted: newCompleted) == true else {
            logger.error("Failed to toggle completed for reminder \(reminder.id)")
            return
        }
        projectRepository?.touchUpdatedAt(id: reminder.projectId)
        loadData()
    }

    func projectName(for reminder: Reminder) -> String? {
        projectRepository?.fetchById(id: reminder.projectId)?.name
    }

    // MARK: - Statistics

    var pendingCount: Int {
        reminders.filter { !$0.isCompleted }.count
    }

    var overdueCount: Int {
        reminders.filter(\.isOverdue).count
    }

    // MARK: - Private

    private func applyFilter() {
        let filtered: [Reminder]
        switch selectedFilter {
        case .all:
            filtered = reminders
        case .pending:
            filtered = reminders.filter { !$0.isCompleted }
        case .completed:
            filtered = reminders.filter(\.isCompleted)
        case .overdue:
            filtered = reminders.filter(\.isOverdue)
        }
        filteredReminders = filtered.sorted { lhs, rhs in
            if lhs.isCompleted != rhs.isCompleted { return !lhs.isCompleted }
            guard let lDate = lhs.dueDate else { return false }
            guard let rDate = rhs.dueDate else { return true }
            return lDate < rDate
        }
    }
}
