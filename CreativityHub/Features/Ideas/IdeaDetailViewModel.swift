import Foundation
import os

@MainActor
@Observable
final class IdeaDetailViewModel {

    // MARK: - State

    var idea: Idea
    var tags: [Tag] = []
    var allTags: [Tag] = []

    let projectId: UUID

    // MARK: - Private

    private let ideaRepository: IdeaRepository?
    private let tagRepository: TagRepository?
    private let projectRepository: ProjectRepository?
    private let logger: Logger

    // MARK: - Init

    init(idea: Idea, projectId: UUID, databaseManager: DatabaseManager = .shared) {
        self.idea = idea
        self.projectId = projectId
        self.ideaRepository = databaseManager.ideaRepository
        self.tagRepository = databaseManager.tagRepository
        self.projectRepository = databaseManager.projectRepository
        self.logger = Logger(
            subsystem: Bundle.main.bundleIdentifier ?? "-",
            category: "IdeaDetailViewModel"
        )
    }

    // MARK: - Public

    func loadData() {
        if let refreshed = ideaRepository?.fetchById(id: idea.id) {
            idea = refreshed
        }
        tags = tagRepository?.fetchTagsForIdea(ideaId: idea.id) ?? []
        allTags = tagRepository?.fetchAll() ?? []
    }

    func updateIdea(_ updated: Idea) {
        guard ideaRepository?.update(updated) == true else {
            logger.error("Failed to update idea \(updated.id)")
            return
        }
        idea = updated
        projectRepository?.touchUpdatedAt(id: projectId)
        ActivityLogService.shared.log(projectId: projectId, entityType: .idea, actionType: .updated)
        logger.info("Updated idea \(updated.id)")
    }

    func deleteIdea() -> Bool {
        _ = tagRepository?.deleteLinksForIdea(ideaId: idea.id)
        guard ideaRepository?.delete(id: idea.id) == true else {
            logger.error("Failed to delete idea \(self.idea.id)")
            return false
        }
        projectRepository?.touchUpdatedAt(id: projectId)
        ActivityLogService.shared.log(projectId: projectId, entityType: .idea, actionType: .deleted)
        logger.info("Deleted idea \(self.idea.id)")
        return true
    }

    func addTag(_ tag: Tag) {
        guard tagRepository?.linkTagToIdea(tagId: tag.id, ideaId: idea.id) == true else {
            logger.error("Failed to link tag \(tag.id) to idea \(self.idea.id)")
            return
        }
        tags.append(tag)
        ActivityLogService.shared.log(projectId: projectId, entityType: .idea, actionType: .linked)
        logger.info("Linked tag \(tag.id) to idea \(self.idea.id)")
    }

    func removeTag(_ tag: Tag) {
        guard tagRepository?.unlinkTagFromIdea(tagId: tag.id, ideaId: idea.id) == true else {
            logger.error("Failed to unlink tag \(tag.id) from idea \(self.idea.id)")
            return
        }
        tags.removeAll { $0.id == tag.id }
        ActivityLogService.shared.log(projectId: projectId, entityType: .idea, actionType: .unlinked)
        logger.info("Unlinked tag \(tag.id) from idea \(self.idea.id)")
    }

    func createAndAddTag(name: String, color: String) {
        let tag = Tag(name: name, color: color)
        guard tagRepository?.insert(tag) == true else {
            logger.error("Failed to create tag")
            return
        }
        addTag(tag)
        allTags = tagRepository?.fetchAll() ?? []
    }

    var unlinkedTags: [Tag] {
        let linkedIds = Set(tags.map(\.id))
        return allTags.filter { !linkedIds.contains($0.id) }
    }
}
