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

@MainActor
@Observable
final class ProjectsListViewModel {

    // MARK: - State

    var projects: [Project] = []
    var filteredProjects: [Project] = []
    var selectedFilter: ProjectFilter = .all
    var isLoading = false

    var showAddSheet = false
    var projectToEdit: Project?

    // MARK: - Private

    private let databaseManager: DatabaseManager
    private let projectRepository: ProjectRepository?
    private let logger: Logger

    // MARK: - Init

    init(databaseManager: DatabaseManager = .shared) {
        self.databaseManager = databaseManager
        self.projectRepository = databaseManager.projectRepository
        self.logger = Logger(
            subsystem: Bundle.main.bundleIdentifier ?? "-",
            category: "ProjectsListViewModel"
        )
    }

    // MARK: - Public

    func loadProjects() {
        isLoading = true
        projects = projectRepository?.fetchAll() ?? []
        applyFilter()
        isLoading = false
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
        logger.info("Added project \(project.id)")
        loadProjects()
    }

    func updateProject(_ project: Project) {
        guard projectRepository?.update(project) == true else {
            logger.error("Failed to update project \(project.id)")
            return
        }
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
        logger.info("Toggled pin for project \(project.id): \(newPinned)")
        loadProjects()
    }
}
