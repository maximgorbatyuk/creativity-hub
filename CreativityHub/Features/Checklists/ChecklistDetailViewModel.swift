import Foundation
import SwiftUI
import os

enum ChecklistItemFilter: String, CaseIterable {
    case all
    case pending
    case completed
    case overdue

    var displayName: String {
        switch self {
        case .all: return L("checklist.filter.all")
        case .pending: return L("checklist.filter.pending")
        case .completed: return L("checklist.filter.completed")
        case .overdue: return L("checklist.filter.overdue")
        }
    }
}

@MainActor
@Observable
final class ChecklistDetailViewModel {

    // MARK: - State

    var checklist: Checklist
    var items: [ChecklistItem] = []
    var filteredItems: [ChecklistItem] = []
    var selectedFilter: ChecklistItemFilter = .all
    var isLoading = false

    var showAddItemSheet = false
    var itemToEdit: ChecklistItem?
    var showWorkLogSheet = false
    var pendingWorkLogChecklistItem: ChecklistItem?
    var showDoneConfirmation = false
    var itemToConfirmDone: ChecklistItem?

    let projectId: UUID

    // MARK: - Private

    private let checklistItemRepository: ChecklistItemRepository?
    private let checklistRepository: ChecklistRepository?
    private let projectRepository: ProjectRepository?
    private let workLogRepository: WorkLogRepository?
    private let logger: Logger

    // MARK: - Init

    init(checklist: Checklist, projectId: UUID, databaseManager: DatabaseManager = .shared) {
        self.checklist = checklist
        self.projectId = projectId
        self.checklistItemRepository = databaseManager.checklistItemRepository
        self.checklistRepository = databaseManager.checklistRepository
        self.projectRepository = databaseManager.projectRepository
        self.workLogRepository = databaseManager.workLogRepository
        self.logger = Logger(
            subsystem: Bundle.main.bundleIdentifier ?? "-",
            category: "ChecklistDetailViewModel"
        )
    }

    // MARK: - Public

    func loadData() {
        isLoading = true
        if let refreshed = checklistRepository?.fetchById(id: checklist.id) {
            checklist = refreshed
        }
        items = checklistItemRepository?.fetchByChecklistId(checklistId: checklist.id) ?? []
        applyFilter()
        isLoading = false
    }

    func applyFilter() {
        switch selectedFilter {
        case .all:
            filteredItems = items
        case .pending:
            filteredItems = items.filter { !$0.isCompleted }
        case .completed:
            filteredItems = items.filter(\.isCompleted)
        case .overdue:
            filteredItems = items.filter(\.isOverdue)
        }
    }

    func addItem(_ item: ChecklistItem) {
        guard checklistItemRepository?.insert(item) == true else {
            logger.error("Failed to insert checklist item")
            return
        }
        projectRepository?.touchUpdatedAt(id: projectId)
        ActivityLogService.shared.log(projectId: projectId, entityType: .checklistItem, actionType: .created)
        logger.info("Added checklist item \(item.id)")
        loadData()
    }

    func updateItem(_ item: ChecklistItem) {
        guard checklistItemRepository?.update(item) == true else {
            logger.error("Failed to update checklist item \(item.id)")
            return
        }
        projectRepository?.touchUpdatedAt(id: projectId)
        ActivityLogService.shared.log(projectId: projectId, entityType: .checklistItem, actionType: .updated)
        logger.info("Updated checklist item \(item.id)")
        loadData()
    }

    func deleteItem(_ item: ChecklistItem) {
        guard workLogRepository?.detachChecklistItem(checklistItemId: item.id) == true else {
            logger.error("Failed to detach work log links for checklist item \(item.id)")
            return
        }
        guard checklistItemRepository?.delete(id: item.id) == true else {
            logger.error("Failed to delete checklist item \(item.id)")
            return
        }
        projectRepository?.touchUpdatedAt(id: projectId)
        ActivityLogService.shared.log(projectId: projectId, entityType: .checklistItem, actionType: .deleted)
        logger.info("Deleted checklist item \(item.id)")
        loadData()
    }

    func toggleItemCompletion(_ item: ChecklistItem) {
        guard checklistItemRepository?.toggleCompletion(id: item.id) == true else {
            logger.error("Failed to toggle checklist item \(item.id)")
            return
        }
        projectRepository?.touchUpdatedAt(id: projectId)
        ActivityLogService.shared.log(projectId: projectId, entityType: .checklistItem, actionType: .statusChanged)
        logger.info("Toggled checklist item \(item.id)")
        loadData()
    }

    func markDoneAndLogTime(_ item: ChecklistItem) {
        guard !item.isCompleted else { return }
        guard checklistItemRepository?.toggleCompletion(id: item.id) == true else {
            logger.error("Failed to toggle checklist item \(item.id)")
            return
        }
        projectRepository?.touchUpdatedAt(id: projectId)
        ActivityLogService.shared.log(projectId: projectId, entityType: .checklistItem, actionType: .statusChanged)
        pendingWorkLogChecklistItem = item
        showWorkLogSheet = true
        loadData()
    }

    func addWorkLog(_ workLog: WorkLog) {
        guard workLogRepository?.insert(workLog) == true else {
            logger.error("Failed to insert work log")
            return
        }
        projectRepository?.touchUpdatedAt(id: projectId)
        ActivityLogService.shared.log(projectId: projectId, entityType: .workLog, actionType: .created)
        logger.info("Added work log \(workLog.id) from checklist")
    }

    func moveItem(from source: IndexSet, to destination: Int) {
        guard selectedFilter == .all else {
            logger.warning("Attempted to reorder checklist items with active filter")
            return
        }

        var updated = items
        updated.move(fromOffsets: source, toOffset: destination)
        for (index, _) in updated.enumerated() {
            updated[index].sortOrder = index
        }
        guard checklistItemRepository?.updateSortOrders(updated) == true else {
            logger.error("Failed to reorder checklist items")
            return
        }
        items = updated
        applyFilter()
        logger.info("Reordered checklist items")
    }

    var nextSortOrder: Int {
        checklistItemRepository?.nextSortOrder(checklistId: checklist.id) ?? 0
    }

    var progress: (checked: Int, total: Int) {
        let checked = items.filter(\.isCompleted).count
        return (checked: checked, total: items.count)
    }

    var progressPercentage: Double {
        guard progress.total > 0 else { return 0 }
        return Double(progress.checked) / Double(progress.total)
    }
}
