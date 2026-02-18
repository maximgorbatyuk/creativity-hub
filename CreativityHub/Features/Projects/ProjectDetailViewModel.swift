import Foundation
import os

struct ProjectSectionCounts {
    var checklists: Int = 0
    var ideas: Int = 0
    var notes: Int = 0
    var expenses: Int = 0
}

@MainActor
@Observable
final class ProjectDetailViewModel {

    // MARK: - State

    var project: Project
    var sectionCounts = ProjectSectionCounts()
    var checklistProgress: (checked: Int, total: Int) = (0, 0)
    var totalExpenses: Decimal = 0

    // MARK: - Private

    private let projectRepository: ProjectRepository?
    private let checklistRepository: ChecklistRepository?
    private let checklistItemRepository: ChecklistItemRepository?
    private let ideaRepository: IdeaRepository?
    private let noteRepository: NoteRepository?
    private let expenseRepository: ExpenseRepository?
    private let logger: Logger

    // MARK: - Init

    init(project: Project, databaseManager: DatabaseManager = .shared) {
        self.project = project
        self.projectRepository = databaseManager.projectRepository
        self.checklistRepository = databaseManager.checklistRepository
        self.checklistItemRepository = databaseManager.checklistItemRepository
        self.ideaRepository = databaseManager.ideaRepository
        self.noteRepository = databaseManager.noteRepository
        self.expenseRepository = databaseManager.expenseRepository
        self.logger = Logger(
            subsystem: Bundle.main.bundleIdentifier ?? "-",
            category: "ProjectDetailViewModel"
        )
    }

    // MARK: - Public

    func loadData() {
        if let refreshed = projectRepository?.fetchById(id: project.id) {
            project = refreshed
        }
        loadSectionCounts()
    }

    func updateProject(_ updated: Project) {
        guard projectRepository?.update(updated) == true else {
            logger.error("Failed to update project \(updated.id)")
            return
        }
        project = updated
        logger.info("Updated project \(updated.id)")
    }

    func deleteProject() -> Bool {
        guard projectRepository?.delete(id: project.id) == true else {
            logger.error("Failed to delete project \(self.project.id)")
            return false
        }
        logger.info("Deleted project \(self.project.id)")
        return true
    }

    func togglePin() {
        let newPinned = !project.isPinned
        guard projectRepository?.togglePin(id: project.id, isPinned: newPinned) == true else {
            logger.error("Failed to toggle pin for project \(self.project.id)")
            return
        }
        project.isPinned = newPinned
        logger.info("Toggled pin for project \(self.project.id): \(newPinned)")
    }

    func updateStatus(_ status: ProjectStatus) {
        guard projectRepository?.updateStatus(id: project.id, status: status) == true else {
            logger.error("Failed to update status for project \(self.project.id)")
            return
        }
        project.status = status
        logger.info("Updated status for project \(self.project.id): \(status.rawValue)")
    }

    var progressPercentage: Double {
        guard checklistProgress.total > 0 else { return 0 }
        return Double(checklistProgress.checked) / Double(checklistProgress.total)
    }

    // MARK: - Private

    private func loadSectionCounts() {
        let projectId = project.id

        sectionCounts.checklists = checklistRepository?.countByProjectId(projectId: projectId) ?? 0
        sectionCounts.ideas = ideaRepository?.countByProjectId(projectId: projectId) ?? 0
        sectionCounts.notes = noteRepository?.countByProjectId(projectId: projectId) ?? 0
        sectionCounts.expenses = (expenseRepository?.fetchByProjectId(projectId: projectId) ?? []).count

        loadChecklistProgress(projectId: projectId)
        loadTotalExpenses(projectId: projectId)
    }

    private func loadChecklistProgress(projectId: UUID) {
        let checklists = checklistRepository?.fetchByProjectId(projectId: projectId) ?? []
        var totalChecked = 0
        var totalItems = 0

        for checklist in checklists {
            let items = checklistItemRepository?.fetchByChecklistId(checklistId: checklist.id) ?? []
            totalItems += items.count
            totalChecked += items.filter(\.isCompleted).count
        }

        checklistProgress = (checked: totalChecked, total: totalItems)
    }

    private func loadTotalExpenses(projectId: UUID) {
        let expenses = expenseRepository?.fetchByProjectId(projectId: projectId) ?? []
        totalExpenses = expenses
            .filter { $0.status == .paid }
            .reduce(Decimal.zero) { $0 + $1.amount }
    }
}
