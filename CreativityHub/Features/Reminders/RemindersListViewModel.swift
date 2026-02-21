import Foundation
import os

enum ReminderFilter: Equatable {
    case all
    case pending
    case completed
    case overdue

    var displayName: String {
        switch self {
        case .all: return L("reminder.filter.all")
        case .pending: return L("reminder.filter.pending")
        case .completed: return L("reminder.filter.completed")
        case .overdue: return L("reminder.filter.overdue")
        }
    }
}

enum ReminderSortOrder: String, CaseIterable {
    case dueDate
    case priority
    case created

    var displayName: String {
        switch self {
        case .dueDate: return L("reminder.sort.due_date")
        case .priority: return L("reminder.sort.priority")
        case .created: return L("reminder.sort.created")
        }
    }
}

@MainActor
@Observable
final class RemindersListViewModel {

    // MARK: - State

    var reminders: [Reminder] = []
    var filteredReminders: [Reminder] = []
    var selectedFilter: ReminderFilter = .all {
        didSet { applyFilter() }
    }
    var sortOrder: ReminderSortOrder = .dueDate {
        didSet { applyFilter() }
    }
    var isLoading = false

    var showAddSheet = false
    var reminderToEdit: Reminder?

    let projectId: UUID

    // MARK: - Private

    private let reminderRepository: ReminderRepository?
    private let projectRepository: ProjectRepository?
    private let logger: Logger

    // MARK: - Init

    init(projectId: UUID, databaseManager: DatabaseManager = .shared) {
        self.projectId = projectId
        self.reminderRepository = databaseManager.reminderRepository
        self.projectRepository = databaseManager.projectRepository
        self.logger = Logger(
            subsystem: Bundle.main.bundleIdentifier ?? "-",
            category: "RemindersListViewModel"
        )
    }

    // MARK: - Public

    func loadData() {
        isLoading = true
        reminders = reminderRepository?.fetchByProjectId(projectId: projectId) ?? []
        applyFilter()
        isLoading = false
    }

    func addReminder(_ reminder: Reminder) {
        guard reminderRepository?.insert(reminder) == true else {
            logger.error("Failed to insert reminder")
            return
        }
        projectRepository?.touchUpdatedAt(id: projectId)
        ActivityLogService.shared.log(projectId: projectId, entityType: .reminder, actionType: .created)
        logger.info("Added reminder \(reminder.id)")
        loadData()
    }

    func updateReminder(_ reminder: Reminder) {
        guard reminderRepository?.update(reminder) == true else {
            logger.error("Failed to update reminder \(reminder.id)")
            return
        }
        projectRepository?.touchUpdatedAt(id: projectId)
        ActivityLogService.shared.log(projectId: projectId, entityType: .reminder, actionType: .updated)
        logger.info("Updated reminder \(reminder.id)")
        loadData()
    }

    func deleteReminder(_ reminder: Reminder) {
        guard reminderRepository?.delete(id: reminder.id) == true else {
            logger.error("Failed to delete reminder \(reminder.id)")
            return
        }
        projectRepository?.touchUpdatedAt(id: projectId)
        ActivityLogService.shared.log(projectId: projectId, entityType: .reminder, actionType: .deleted)
        logger.info("Deleted reminder \(reminder.id)")
        loadData()
    }

    func toggleCompleted(_ reminder: Reminder) {
        let newCompleted = !reminder.isCompleted
        guard reminderRepository?.toggleCompleted(id: reminder.id, isCompleted: newCompleted) == true else {
            logger.error("Failed to toggle completed for reminder \(reminder.id)")
            return
        }
        projectRepository?.touchUpdatedAt(id: projectId)
        ActivityLogService.shared.log(projectId: projectId, entityType: .reminder, actionType: .statusChanged)
        logger.info("Toggled completed for reminder \(reminder.id): \(newCompleted)")
        loadData()
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
        filteredReminders = applySorting(filtered)
    }

    private func applySorting(_ items: [Reminder]) -> [Reminder] {
        switch sortOrder {
        case .dueDate:
            return items.sorted { lhs, rhs in
                if lhs.isCompleted != rhs.isCompleted { return !lhs.isCompleted }
                guard let lDate = lhs.dueDate else { return false }
                guard let rDate = rhs.dueDate else { return true }
                return lDate < rDate
            }
        case .priority:
            return items.sorted { lhs, rhs in
                if lhs.isCompleted != rhs.isCompleted { return !lhs.isCompleted }
                return lhs.priority.sortValue > rhs.priority.sortValue
            }
        case .created:
            return items.sorted { $0.createdAt > $1.createdAt }
        }
    }
}
