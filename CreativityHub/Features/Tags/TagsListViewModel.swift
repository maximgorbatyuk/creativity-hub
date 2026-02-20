import Foundation

@MainActor
@Observable
class TagsListViewModel {
    var tags: [Tag] = []
    var tagToDelete: Tag?
    var showDeleteConfirmation = false

    private let tagRepository = DatabaseManager.shared.tagRepository

    func loadTags() {
        tags = tagRepository?.fetchAll() ?? []
    }

    func deleteTag() {
        guard let tag = tagToDelete else { return }
        _ = tagRepository?.delete(id: tag.id)
        loadTags()
        tagToDelete = nil
    }

    func createTag(_ tag: Tag) {
        _ = tagRepository?.insert(tag)
        loadTags()
    }

    func updateTag(_ tag: Tag) {
        _ = tagRepository?.update(tag)
        loadTags()
    }

    func confirmDelete(_ tag: Tag) {
        tagToDelete = tag
        showDeleteConfirmation = true
    }
}
