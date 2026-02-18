import Foundation

struct Note: Codable, Identifiable, Equatable, Hashable {
    let id: UUID
    let projectId: UUID
    var title: String
    var content: String
    var isPinned: Bool
    var sortOrder: Int
    let createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        projectId: UUID,
        title: String,
        content: String = "",
        isPinned: Bool = false,
        sortOrder: Int = 0,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.projectId = projectId
        self.title = title
        self.content = content
        self.isPinned = isPinned
        self.sortOrder = sortOrder
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var contentPreview: String {
        let maxLength = 100
        if content.count <= maxLength { return content }
        return String(content.prefix(maxLength)) + "..."
    }

    var isEmpty: Bool {
        title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var hasContent: Bool {
        !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
