import Foundation
import os

enum IdeaSourceFilter: Equatable {
    case all
    case source(IdeaSourceType)

    var displayName: String {
        switch self {
        case .all: return L("idea.filter.all")
        case .source(let type): return type.displayName
        }
    }
}

enum IdeaListLayout: String {
    case list
    case grid
}

@MainActor
@Observable
final class IdeasListViewModel {

    // MARK: - State

    var ideas: [Idea] = []
    var filteredIdeas: [Idea] = []
    var selectedFilter: IdeaSourceFilter = .all
    var layout: IdeaListLayout = .list
    var isLoading = false

    var showAddSheet = false
    var ideaToEdit: Idea?

    let projectId: UUID

    // MARK: - Private

    private let ideaRepository: IdeaRepository?
    private let tagRepository: TagRepository?
    private let projectRepository: ProjectRepository?
    private let logger: Logger

    // MARK: - Init

    init(projectId: UUID, databaseManager: DatabaseManager = .shared) {
        self.projectId = projectId
        self.ideaRepository = databaseManager.ideaRepository
        self.tagRepository = databaseManager.tagRepository
        self.projectRepository = databaseManager.projectRepository
        self.logger = Logger(
            subsystem: Bundle.main.bundleIdentifier ?? "-",
            category: "IdeasListViewModel"
        )
    }

    // MARK: - Public

    func loadData() {
        isLoading = true
        ideas = ideaRepository?.fetchByProjectId(projectId: projectId) ?? []
        applyFilter()
        isLoading = false
    }

    func applyFilter() {
        switch selectedFilter {
        case .all:
            filteredIdeas = ideas
        case .source(let type):
            filteredIdeas = ideas.filter { $0.sourceType == type }
        }
    }

    func addIdea(_ idea: Idea) {
        guard ideaRepository?.insert(idea) == true else {
            logger.error("Failed to insert idea")
            return
        }
        projectRepository?.touchUpdatedAt(id: projectId)
        ActivityLogService.shared.log(projectId: projectId, entityType: .idea, actionType: .created)
        logger.info("Added idea \(idea.id)")
        loadData()
    }

    func updateIdea(_ idea: Idea) {
        guard ideaRepository?.update(idea) == true else {
            logger.error("Failed to update idea \(idea.id)")
            return
        }
        projectRepository?.touchUpdatedAt(id: projectId)
        ActivityLogService.shared.log(projectId: projectId, entityType: .idea, actionType: .updated)
        logger.info("Updated idea \(idea.id)")
        loadData()
    }

    func deleteIdea(_ idea: Idea) {
        _ = tagRepository?.deleteLinksForIdea(ideaId: idea.id)
        guard ideaRepository?.delete(id: idea.id) == true else {
            logger.error("Failed to delete idea \(idea.id)")
            return
        }
        projectRepository?.touchUpdatedAt(id: projectId)
        ActivityLogService.shared.log(projectId: projectId, entityType: .idea, actionType: .deleted)
        logger.info("Deleted idea \(idea.id)")
        loadData()
    }

    var availableSourceTypes: [IdeaSourceType] {
        let types = Set(ideas.map(\.sourceType))
        return IdeaSourceType.allCases.filter { types.contains($0) }
    }
}
