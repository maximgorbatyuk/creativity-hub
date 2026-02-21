import Foundation

enum ActivityEntityType: String, Codable, CaseIterable {
    case project
    case workLog
    case idea
    case checklist
    case checklistItem
    case document
    case note
    case expense
    case expenseCategory
    case reminder
}

enum ActivityActionType: String, Codable, CaseIterable {
    case created
    case updated
    case deleted
    case statusChanged
    case linked
    case unlinked
}

struct ActivityLog: Codable, Identifiable, Equatable, Hashable {
    let id: UUID
    let projectId: UUID
    let entityType: ActivityEntityType
    let actionType: ActivityActionType
    let createdAt: Date

    init(
        id: UUID = UUID(),
        projectId: UUID,
        entityType: ActivityEntityType,
        actionType: ActivityActionType,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.projectId = projectId
        self.entityType = entityType
        self.actionType = actionType
        self.createdAt = createdAt
    }
}
