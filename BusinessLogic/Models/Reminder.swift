import Foundation
import SwiftUI

struct Reminder: Codable, Identifiable, Equatable, Hashable {
    let id: UUID
    let projectId: UUID
    var title: String
    var notes: String?
    var dueDate: Date?
    var isCompleted: Bool
    var priority: ItemPriority
    let createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        projectId: UUID,
        title: String,
        notes: String? = nil,
        dueDate: Date? = nil,
        isCompleted: Bool = false,
        priority: ItemPriority = .none,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.projectId = projectId
        self.title = title
        self.notes = notes
        self.dueDate = dueDate
        self.isCompleted = isCompleted
        self.priority = priority
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var isOverdue: Bool {
        guard let dueDate = dueDate, !isCompleted else { return false }
        return dueDate < Date()
    }

    var isDueToday: Bool {
        guard let dueDate = dueDate, !isCompleted else { return false }
        return Calendar.current.isDateInToday(dueDate)
    }

    var isDueSoon: Bool {
        guard let dueDate = dueDate, !isCompleted else { return false }
        let twoDaysFromNow = Calendar.current.date(byAdding: .day, value: 2, to: Date()) ?? Date()
        return dueDate <= twoDaysFromNow && dueDate > Date()
    }

    var hasNotes: Bool {
        guard let notes = notes else { return false }
        return !notes.isEmpty
    }

    var hasDueDate: Bool {
        dueDate != nil
    }
}
