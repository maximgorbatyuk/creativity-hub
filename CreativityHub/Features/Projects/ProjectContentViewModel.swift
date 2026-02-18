import Foundation
import os

@MainActor
@Observable
final class ProjectContentViewModel {
    // MARK: - State

    var allProjects: [Project] = []
    var selectedProjectId: UUID?
    var selectedProject: Project?
    var sectionCounts = ProjectSectionCounts()
    var isLoading: Bool = false

    var checklistProgress: (checked: Int, total: Int) = (0, 0)
    var totalExpenses: Decimal = 0

    // Preview data (up to 3 items per section)
    var previewChecklists: [Checklist] = []
    var checklistItemProgress: [UUID: (checked: Int, total: Int)] = [:]
    var previewIdeas: [Idea] = []
    var previewNotes: [Note] = []
    var previewDocuments: [Document] = []
    var previewExpenses: [Expense] = []
    var previewReminders: [Reminder] = []

    // MARK: - Private

    private let databaseManager: DatabaseManager
    private let projectRepository: ProjectRepository?
    private let checklistRepository: ChecklistRepository?
    private let checklistItemRepository: ChecklistItemRepository?
    private let ideaRepository: IdeaRepository?
    private let noteRepository: NoteRepository?
    private let documentRepository: DocumentRepository?
    private let expenseRepository: ExpenseRepository?
    private let reminderRepository: ReminderRepository?
    private let logger: Logger

    private let selectedProjectKey = "selectedProjectId"

    // MARK: - Init

    init(databaseManager: DatabaseManager = .shared) {
        self.databaseManager = databaseManager
        projectRepository = databaseManager.projectRepository
        checklistRepository = databaseManager.checklistRepository
        checklistItemRepository = databaseManager.checklistItemRepository
        ideaRepository = databaseManager.ideaRepository
        noteRepository = databaseManager.noteRepository
        documentRepository = databaseManager.documentRepository
        expenseRepository = databaseManager.expenseRepository
        reminderRepository = databaseManager.reminderRepository
        logger = Logger(
            subsystem: Bundle.main.bundleIdentifier ?? "-",
            category: "ProjectContentViewModel"
        )
    }

    // MARK: - Public

    func loadInitialData() {
        isLoading = true

        allProjects = projectRepository?.fetchAll() ?? []

        // Restore previously selected project or auto-select
        if let savedIdString = UserDefaults.standard.string(forKey: selectedProjectKey),
           let savedId = UUID(uuidString: savedIdString),
           allProjects.contains(where: { $0.id == savedId })
        {
            selectProject(id: savedId)
        } else {
            // Auto-select: active > most recent by updatedAt
            let activeProject = allProjects.first(where: { $0.isActive })
            let mostRecent = allProjects.sorted(by: { $0.updatedAt > $1.updatedAt }).first

            if let project = activeProject ?? mostRecent {
                selectProject(id: project.id)
            }
        }

        isLoading = false
    }

    func selectProject(id: UUID) {
        selectedProjectId = id
        selectedProject = projectRepository?.fetchById(id: id)

        UserDefaults.standard.set(id.uuidString, forKey: selectedProjectKey)

        loadSectionData()
    }

    func refreshData() {
        allProjects = projectRepository?.fetchAll() ?? []

        if let selectedId = selectedProjectId,
           !allProjects.contains(where: { $0.id == selectedId })
        {
            // Selected project was deleted, select another
            selectedProjectId = nil
            selectedProject = nil

            if let firstProject = allProjects.first(where: { $0.isActive }) ?? allProjects.first {
                selectProject(id: firstProject.id)
            } else {
                resetSectionData()
            }
        } else if let selectedId = selectedProjectId {
            selectedProject = projectRepository?.fetchById(id: selectedId)
            loadSectionData()
        }
    }

    func addProject(_ project: Project) {
        guard projectRepository?.insert(project) == true else {
            logger.error("Failed to insert project \(project.id)")
            return
        }
        refreshData()
        selectProject(id: project.id)
        logger.info("Added project \(project.id)")
    }

    func updateProject(_ updated: Project) {
        guard projectRepository?.update(updated) == true else {
            logger.error("Failed to update project \(updated.id)")
            return
        }
        selectedProject = updated
        refreshData()
        logger.info("Updated project \(updated.id)")
    }

    func deleteProject() -> Bool {
        guard let projectId = selectedProjectId else { return false }
        guard databaseManager.deleteProjectCascade(projectId: projectId) else {
            logger.error("Failed to delete project \(projectId)")
            return false
        }
        logger.info("Deleted project \(projectId)")
        selectedProjectId = nil
        selectedProject = nil
        refreshData()
        return true
    }

    func togglePin() {
        guard var project = selectedProject else { return }
        let newPinned = !project.isPinned
        guard projectRepository?.togglePin(id: project.id, isPinned: newPinned) == true else {
            logger.error("Failed to toggle pin for project \(project.id)")
            return
        }
        project.isPinned = newPinned
        selectedProject = project
        logger.info("Toggled pin for project \(project.id): \(newPinned)")
    }

    func updateStatus(_ status: ProjectStatus) {
        guard var project = selectedProject else { return }
        guard projectRepository?.updateStatus(id: project.id, status: status) == true else {
            logger.error("Failed to update status for project \(project.id)")
            return
        }
        project.status = status
        selectedProject = project
        logger.info("Updated status for project \(project.id): \(status.rawValue)")
    }

    var progressPercentage: Double {
        guard checklistProgress.total > 0 else { return 0 }
        return Double(checklistProgress.checked) / Double(checklistProgress.total)
    }

    // MARK: - Private

    private func loadSectionData() {
        guard let projectId = selectedProjectId else {
            resetSectionData()
            return
        }

        // Load counts
        sectionCounts.checklists = checklistRepository?.countByProjectId(projectId: projectId) ?? 0
        sectionCounts.ideas = ideaRepository?.countByProjectId(projectId: projectId) ?? 0
        sectionCounts.notes = noteRepository?.countByProjectId(projectId: projectId) ?? 0
        sectionCounts.documents = documentRepository?.countByProjectId(projectId: projectId) ?? 0
        sectionCounts.reminders = reminderRepository?.countByProjectId(projectId: projectId) ?? 0

        // Expenses count and total
        let allExpenses = expenseRepository?.fetchByProjectId(projectId: projectId) ?? []
        sectionCounts.expenses = allExpenses.count
        totalExpenses = allExpenses
            .filter { $0.status == .paid }
            .reduce(Decimal.zero) { $0 + $1.amount }

        // Preview expenses (3 most recent by date)
        previewExpenses = Array(allExpenses.sorted { $0.date > $1.date }.prefix(3))

        // Preview checklists (first 3) with per-checklist progress
        let allChecklists = checklistRepository?.fetchByProjectId(projectId: projectId) ?? []
        previewChecklists = Array(allChecklists.prefix(3))

        var totalChecked = 0
        var totalItems = 0
        checklistItemProgress = [:]

        for checklist in allChecklists {
            let items = checklistItemRepository?.fetchByChecklistId(checklistId: checklist.id) ?? []
            let checked = items.filter(\.isCompleted).count
            totalItems += items.count
            totalChecked += checked

            if previewChecklists.contains(where: { $0.id == checklist.id }) {
                checklistItemProgress[checklist.id] = (checked: checked, total: items.count)
            }
        }
        checklistProgress = (checked: totalChecked, total: totalItems)

        // Preview ideas (first 3)
        previewIdeas = Array((ideaRepository?.fetchByProjectId(projectId: projectId) ?? []).prefix(3))

        // Preview notes (first 3)
        previewNotes = Array((noteRepository?.fetchByProjectId(projectId: projectId) ?? []).prefix(3))

        // Preview documents (first 3)
        previewDocuments = Array((documentRepository?.fetchByProjectId(projectId: projectId) ?? []).prefix(3))

        // Preview reminders (non-completed first 3)
        let allReminders = reminderRepository?.fetchByProjectId(projectId: projectId) ?? []
        previewReminders = Array(allReminders.filter { !$0.isCompleted }.prefix(3))

        logger.info("Loaded section data for project \(projectId)")
    }

    private func resetSectionData() {
        sectionCounts = ProjectSectionCounts()
        checklistProgress = (0, 0)
        totalExpenses = 0
        previewChecklists = []
        checklistItemProgress = [:]
        previewIdeas = []
        previewNotes = []
        previewDocuments = []
        previewExpenses = []
        previewReminders = []
    }
}
