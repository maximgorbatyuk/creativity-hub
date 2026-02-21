import Foundation
import os

@MainActor
@Observable
final class WorkLogsListViewModel {

    // MARK: - State

    var workLogs: [WorkLog] = []
    var isLoading = false
    var showAddSheet = false
    var totalMinutes: Int = 0

    let projectId: UUID

    // MARK: - Private

    private let workLogRepository: WorkLogRepository?
    private let checklistRepository: ChecklistRepository?
    private let checklistItemRepository: ChecklistItemRepository?
    private let projectRepository: ProjectRepository?
    private let logger: Logger

    // MARK: - Init

    init(projectId: UUID, databaseManager: DatabaseManager = .shared) {
        self.projectId = projectId
        self.workLogRepository = databaseManager.workLogRepository
        self.checklistRepository = databaseManager.checklistRepository
        self.checklistItemRepository = databaseManager.checklistItemRepository
        self.projectRepository = databaseManager.projectRepository
        self.logger = Logger(
            subsystem: Bundle.main.bundleIdentifier ?? "-",
            category: "WorkLogsListViewModel"
        )
    }

    // MARK: - Public

    func loadData() {
        isLoading = true
        workLogs = workLogRepository?.fetchByProjectId(projectId: projectId) ?? []
        totalMinutes = workLogRepository?.totalMinutesByProjectId(projectId: projectId) ?? 0
        isLoading = false
    }

    func addWorkLog(_ workLog: WorkLog) {
        guard workLogRepository?.insert(workLog) == true else {
            logger.error("Failed to insert work log")
            return
        }
        projectRepository?.touchUpdatedAt(id: projectId)
        logger.info("Added work log \(workLog.id)")
        loadData()
    }

    func deleteWorkLog(_ workLog: WorkLog) {
        guard workLogRepository?.delete(id: workLog.id) == true else {
            logger.error("Failed to delete work log \(workLog.id)")
            return
        }
        projectRepository?.touchUpdatedAt(id: projectId)
        logger.info("Deleted work log \(workLog.id)")
        loadData()
    }

    var checklistItems: [ChecklistItem] {
        let checklists = checklistRepository?.fetchByProjectId(projectId: projectId) ?? []
        return checklists.flatMap { checklist in
            checklistItemRepository?.fetchByChecklistId(checklistId: checklist.id) ?? []
        }
    }

    func checklistItemName(for workLog: WorkLog) -> String? {
        guard let itemId = workLog.linkedChecklistItemId else { return nil }
        return checklistItemRepository?.fetchById(id: itemId)?.name
    }

    var formattedTotalDuration: String {
        let days = totalMinutes / 1440
        let hours = (totalMinutes % 1440) / 60
        let minutes = totalMinutes % 60

        let dayUnit = L("worklog.duration.unit.day_short")
        let hourUnit = L("worklog.duration.unit.hour_short")
        let minuteUnit = L("worklog.duration.unit.minute_short")

        var parts: [String] = []
        if days > 0 { parts.append("\(days)\(dayUnit)") }
        if hours > 0 { parts.append("\(hours)\(hourUnit)") }
        if minutes > 0 || parts.isEmpty { parts.append("\(minutes)\(minuteUnit)") }
        return parts.joined(separator: " ")
    }
}
