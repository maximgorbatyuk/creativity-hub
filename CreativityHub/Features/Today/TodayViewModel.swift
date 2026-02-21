import Foundation
import os

struct ProjectBiweeklyActivitySeries: Identifiable {
    let project: Project
    let points: [ActivityChartPoint]

    var id: UUID { project.id }
}

@MainActor
@Observable
final class TodayViewModel {

    // MARK: - State

    var activeProjects: [Project] = []
    var overdueChecklistItems: [ChecklistItem] = []
    var upcomingReminders: [Reminder] = []
    var overdueReminders: [Reminder] = []
    var totalProjectCount = 0
    var totalReminderCount = 0
    var totalLoggedMinutes = 0
    var biweeklyActivitySeries: [ProjectBiweeklyActivitySeries] = []
    var isLoading = false

    // MARK: - Private

    private let projectRepository: ProjectRepository?
    private let checklistItemRepository: ChecklistItemRepository?
    private let reminderRepository: ReminderRepository?
    private let workLogRepository: WorkLogRepository?
    private let activityAnalyticsService: ActivityAnalyticsService
    private let logger: Logger

    // MARK: - Init

    init(databaseManager: DatabaseManager = .shared) {
        self.projectRepository = databaseManager.projectRepository
        self.checklistItemRepository = databaseManager.checklistItemRepository
        self.reminderRepository = databaseManager.reminderRepository
        self.workLogRepository = databaseManager.workLogRepository
        self.activityAnalyticsService = .shared
        self.logger = Logger(
            subsystem: Bundle.main.bundleIdentifier ?? "-",
            category: "TodayViewModel"
        )
    }

    // MARK: - Public

    func loadData() {
        isLoading = true
        totalProjectCount = projectRepository?.fetchAll().count ?? 0
        totalReminderCount = reminderRepository?.fetchAll().count ?? 0
        totalLoggedMinutes = workLogRepository?.totalMinutesAll() ?? 0
        let allProjects = projectRepository?.fetchAll() ?? []
        biweeklyActivitySeries = allProjects.map { project in
            ProjectBiweeklyActivitySeries(
                project: project,
                points: activityAnalyticsService.biweeklyActivityCounts(projectId: project.id, months: 6)
            )
        }
        activeProjects = allProjects.filter { $0.status == .active }
        overdueChecklistItems = checklistItemRepository?.fetchOverdueItems() ?? []
        upcomingReminders = reminderRepository?.fetchUpcoming(limit: 5) ?? []
        overdueReminders = reminderRepository?.fetchOverdue() ?? []
        isLoading = false
    }

    // MARK: - Statistics

    var activeProjectCount: Int { activeProjects.count }
    var overdueItemCount: Int { overdueChecklistItems.count }
    var overdueReminderCount: Int { overdueReminders.count }

    var formattedTotalLoggedTime: String {
        let days = totalLoggedMinutes / 1440
        let hours = (totalLoggedMinutes % 1440) / 60

        let dayUnit = L("worklog.duration.unit.day_short")
        let hourUnit = L("worklog.duration.unit.hour_short")
        return "\(days)\(dayUnit) \(hours)\(hourUnit)"
    }

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
