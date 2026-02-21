import Foundation
import os

enum ProjectFilter: String, CaseIterable {
    case all
    case active
    case completed
    case archived

    var displayName: String {
        switch self {
        case .all: return L("project.filter.all")
        case .active: return L("project.status.active")
        case .completed: return L("project.status.completed")
        case .archived: return L("project.status.archived")
        }
    }
}

struct ProjectRowStats {
    let checklistProgress: (checked: Int, total: Int)
    let reminderCount: Int
}

@MainActor
@Observable
final class ProjectsListViewModel {

    // MARK: - State

    var projects: [Project] = []
    var filteredProjects: [Project] = []
    var projectStats: [UUID: ProjectRowStats] = [:]
    var selectedFilter: ProjectFilter = .all
    var isLoading = false

    var showAddSheet = false
    var projectToEdit: Project?

    // MARK: - Private

    private let databaseManager: DatabaseManager
    private let projectRepository: ProjectRepository?
    private let checklistRepository: ChecklistRepository?
    private let checklistItemRepository: ChecklistItemRepository?
    private let reminderRepository: ReminderRepository?
    private let logger: Logger

    // MARK: - Init

    init(databaseManager: DatabaseManager = .shared) {
        self.databaseManager = databaseManager
        self.projectRepository = databaseManager.projectRepository
        self.checklistRepository = databaseManager.checklistRepository
        self.checklistItemRepository = databaseManager.checklistItemRepository
        self.reminderRepository = databaseManager.reminderRepository
        self.logger = Logger(
            subsystem: Bundle.main.bundleIdentifier ?? "-",
            category: "ProjectsListViewModel"
        )
    }

    // MARK: - Public

    func loadProjects() {
        isLoading = true
        projects = projectRepository?.fetchAll() ?? []
        loadStats()
        applyFilter()
        isLoading = false
    }

    func stats(for project: Project) -> ProjectRowStats {
        projectStats[project.id] ?? ProjectRowStats(checklistProgress: (0, 0), reminderCount: 0)
    }

    func applyFilter() {
        switch selectedFilter {
        case .all:
            filteredProjects = projects
        case .active:
            filteredProjects = projects.filter { $0.isActive }
        case .completed:
            filteredProjects = projects.filter { $0.isCompleted }
        case .archived:
            filteredProjects = projects.filter { $0.isArchived }
        }
    }

    func addProject(_ project: Project) {
        guard projectRepository?.insert(project) == true else {
            logger.error("Failed to insert project")
            return
        }
        ActivityLogService.shared.log(projectId: project.id, entityType: .project, actionType: .created)
        logger.info("Added project \(project.id)")
        loadProjects()
    }

    func updateProject(_ project: Project) {
        guard projectRepository?.update(project) == true else {
            logger.error("Failed to update project \(project.id)")
            return
        }
        ActivityLogService.shared.log(projectId: project.id, entityType: .project, actionType: .updated)
        logger.info("Updated project \(project.id)")
        loadProjects()
    }

    func deleteProject(_ project: Project) {
        guard databaseManager.deleteProjectCascade(projectId: project.id) else {
            logger.error("Failed to delete project \(project.id)")
            return
        }
        logger.info("Deleted project \(project.id)")
        loadProjects()
    }

    func togglePin(_ project: Project) {
        let newPinned = !project.isPinned
        guard projectRepository?.togglePin(id: project.id, isPinned: newPinned) == true else {
            logger.error("Failed to toggle pin for project \(project.id)")
            return
        }
        ActivityLogService.shared.log(projectId: project.id, entityType: .project, actionType: .updated)
        logger.info("Toggled pin for project \(project.id): \(newPinned)")
        loadProjects()
    }

    // MARK: - Private

    private func loadStats() {
        var stats: [UUID: ProjectRowStats] = [:]
        for project in projects {
            let checklists = checklistRepository?.fetchByProjectId(projectId: project.id) ?? []
            var totalItems = 0
            var checkedItems = 0
            for checklist in checklists {
                let items = checklistItemRepository?.fetchByChecklistId(checklistId: checklist.id) ?? []
                totalItems += items.count
                checkedItems += items.filter(\.isCompleted).count
            }
            let reminderCount = reminderRepository?.countByProjectId(projectId: project.id) ?? 0
            stats[project.id] = ProjectRowStats(
                checklistProgress: (checked: checkedItems, total: totalItems),
                reminderCount: reminderCount
            )
        }
        projectStats = stats
    }
}
