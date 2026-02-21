import Foundation
import os

enum NoteSortOrder: String, CaseIterable {
    case updated
    case title
    case created

    var displayName: String {
        switch self {
        case .updated: return L("note.sort.updated")
        case .title: return L("note.sort.title")
        case .created: return L("note.sort.created")
        }
    }
}

@MainActor
@Observable
final class NotesListViewModel {

    // MARK: - State

    var notes: [Note] = []
    var isLoading = false
    var sortOrder: NoteSortOrder = .updated

    var showAddSheet = false
    var noteToEdit: Note?

    let projectId: UUID

    // MARK: - Private

    private let noteRepository: NoteRepository?
    private let projectRepository: ProjectRepository?
    private let logger: Logger

    // MARK: - Init

    init(projectId: UUID, databaseManager: DatabaseManager = .shared) {
        self.projectId = projectId
        self.noteRepository = databaseManager.noteRepository
        self.projectRepository = databaseManager.projectRepository
        self.logger = Logger(
            subsystem: Bundle.main.bundleIdentifier ?? "-",
            category: "NotesListViewModel"
        )
    }

    // MARK: - Public

    func loadData() {
        isLoading = true
        let fetched = noteRepository?.fetchByProjectId(projectId: projectId) ?? []
        notes = applySorting(fetched)
        isLoading = false
    }

    func addNote(_ note: Note) {
        guard noteRepository?.insert(note) == true else {
            logger.error("Failed to insert note")
            return
        }
        projectRepository?.touchUpdatedAt(id: projectId)
        ActivityLogService.shared.log(projectId: projectId, entityType: .note, actionType: .created)
        logger.info("Added note \(note.id)")
        loadData()
    }

    func updateNote(_ note: Note) {
        guard noteRepository?.update(note) == true else {
            logger.error("Failed to update note \(note.id)")
            return
        }
        projectRepository?.touchUpdatedAt(id: projectId)
        ActivityLogService.shared.log(projectId: projectId, entityType: .note, actionType: .updated)
        logger.info("Updated note \(note.id)")
        loadData()
    }

    func deleteNote(_ note: Note) {
        guard noteRepository?.delete(id: note.id) == true else {
            logger.error("Failed to delete note \(note.id)")
            return
        }
        projectRepository?.touchUpdatedAt(id: projectId)
        ActivityLogService.shared.log(projectId: projectId, entityType: .note, actionType: .deleted)
        logger.info("Deleted note \(note.id)")
        loadData()
    }

    func togglePin(_ note: Note) {
        let newPinned = !note.isPinned
        guard noteRepository?.togglePin(id: note.id, isPinned: newPinned) == true else {
            logger.error("Failed to toggle pin for note \(note.id)")
            return
        }
        projectRepository?.touchUpdatedAt(id: projectId)
        ActivityLogService.shared.log(projectId: projectId, entityType: .note, actionType: .updated)
        logger.info("Toggled pin for note \(note.id): \(newPinned)")
        loadData()
    }

    // MARK: - Private

    private func applySorting(_ notes: [Note]) -> [Note] {
        let pinned = notes.filter(\.isPinned)
        let unpinned = notes.filter { !$0.isPinned }

        let sortedUnpinned: [Note]
        switch sortOrder {
        case .updated:
            sortedUnpinned = unpinned.sorted { $0.updatedAt > $1.updatedAt }
        case .title:
            sortedUnpinned = unpinned.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        case .created:
            sortedUnpinned = unpinned.sorted { $0.createdAt > $1.createdAt }
        }

        return pinned + sortedUnpinned
    }
}
