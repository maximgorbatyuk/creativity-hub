import Foundation
import SwiftUI
import os

@MainActor
@Observable
final class ChecklistsListViewModel {

    // MARK: - State

    var checklists: [Checklist] = []
    var checklistProgress: [UUID: (checked: Int, total: Int)] = [:]
    var isLoading = false

    var showAddSheet = false
    var checklistToEdit: Checklist?

    let projectId: UUID

    // MARK: - Private

    private let checklistRepository: ChecklistRepository?
    private let checklistItemRepository: ChecklistItemRepository?
    private let workLogRepository: WorkLogRepository?
    private let projectRepository: ProjectRepository?
    private let logger: Logger

    // MARK: - Init

    init(projectId: UUID, databaseManager: DatabaseManager = .shared) {
        self.projectId = projectId
        self.checklistRepository = databaseManager.checklistRepository
        self.checklistItemRepository = databaseManager.checklistItemRepository
        self.workLogRepository = databaseManager.workLogRepository
        self.projectRepository = databaseManager.projectRepository
        self.logger = Logger(
            subsystem: Bundle.main.bundleIdentifier ?? "-",
            category: "ChecklistsListViewModel"
        )
    }

    // MARK: - Public

    func loadData() {
        isLoading = true
        checklists = checklistRepository?.fetchByProjectId(projectId: projectId) ?? []
        loadProgress()
        isLoading = false
    }

    func addChecklist(name: String) {
        let sortOrder = checklistRepository?.nextSortOrder(projectId: projectId) ?? 0
        let checklist = Checklist(
            projectId: projectId,
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            sortOrder: sortOrder
        )
        guard checklistRepository?.insert(checklist) == true else {
            logger.error("Failed to insert checklist")
            return
        }
        projectRepository?.touchUpdatedAt(id: projectId)
        ActivityLogService.shared.log(projectId: projectId, entityType: .checklist, actionType: .created)
        logger.info("Added checklist \(checklist.id)")
        loadData()
    }

    func updateChecklist(id: UUID, name: String) {
        guard var checklist = checklistRepository?.fetchById(id: id) else { return }
        checklist.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard checklistRepository?.update(checklist) == true else {
            logger.error("Failed to update checklist \(id)")
            return
        }
        projectRepository?.touchUpdatedAt(id: projectId)
        ActivityLogService.shared.log(projectId: projectId, entityType: .checklist, actionType: .updated)
        logger.info("Updated checklist \(id)")
        loadData()
    }

    func deleteChecklist(_ checklist: Checklist) {
        let items = checklistItemRepository?.fetchByChecklistId(checklistId: checklist.id) ?? []
        for item in items {
            guard workLogRepository?.detachChecklistItem(checklistItemId: item.id) == true else {
                logger.error("Failed to detach work log links for checklist item \(item.id)")
                return
            }
        }

        _ = checklistItemRepository?.deleteByChecklistId(checklistId: checklist.id)
        guard checklistRepository?.delete(id: checklist.id) == true else {
            logger.error("Failed to delete checklist \(checklist.id)")
            return
        }
        projectRepository?.touchUpdatedAt(id: projectId)
        ActivityLogService.shared.log(projectId: projectId, entityType: .checklist, actionType: .deleted)
        logger.info("Deleted checklist \(checklist.id)")
        loadData()
    }

    func moveChecklist(from source: IndexSet, to destination: Int) {
        var updated = checklists
        updated.move(fromOffsets: source, toOffset: destination)
        for (index, _) in updated.enumerated() {
            updated[index].sortOrder = index
        }
        guard checklistRepository?.updateSortOrders(updated) == true else {
            logger.error("Failed to reorder checklists")
            return
        }
        checklists = updated
        logger.info("Reordered checklists")
    }

    func progress(for checklistId: UUID) -> (checked: Int, total: Int) {
        checklistProgress[checklistId] ?? (0, 0)
    }

    var totalProgress: (checked: Int, total: Int) {
        let checked = checklistProgress.values.reduce(0) { $0 + $1.checked }
        let total = checklistProgress.values.reduce(0) { $0 + $1.total }
        return (checked, total)
    }

    // MARK: - Private

    private func loadProgress() {
        checklistProgress = [:]
        for checklist in checklists {
            let total = checklistItemRepository?.countByChecklistId(checklistId: checklist.id) ?? 0
            let checked = checklistItemRepository?.completedCountByChecklistId(checklistId: checklist.id) ?? 0
            checklistProgress[checklist.id] = (checked: checked, total: total)
        }
    }
}
