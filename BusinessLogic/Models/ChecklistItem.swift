import Foundation
import SwiftUI

// MARK: - ItemPriority

enum ItemPriority: String, Codable, CaseIterable, Identifiable {
    case none
    case low
    case medium
    case high

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .none: return L("priority.none")
        case .low: return L("priority.low")
        case .medium: return L("priority.medium")
        case .high: return L("priority.high")
        }
    }

    var icon: String {
        switch self {
        case .none: return "minus"
        case .low: return "arrow.down"
        case .medium: return "equal"
        case .high: return "arrow.up"
        }
    }

    var color: Color {
        switch self {
        case .none: return .secondary
        case .low: return .blue
        case .medium: return .orange
        case .high: return .red
        }
    }

    var sortValue: Int {
        switch self {
        case .none: return 0
        case .low: return 1
        case .medium: return 2
        case .high: return 3
        }
    }
}

// MARK: - ChecklistItem

struct ChecklistItem: Codable, Identifiable, Equatable {
    let id: UUID
    let checklistId: UUID
    var name: String
    var isCompleted: Bool
    var dueDate: Date?
    var priority: ItemPriority
    var estimatedCost: Decimal?
    var estimatedCostCurrency: Currency?
    var notes: String?
    var sortOrder: Int
    let createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        checklistId: UUID,
        name: String,
        isCompleted: Bool = false,
        dueDate: Date? = nil,
        priority: ItemPriority = .none,
        estimatedCost: Decimal? = nil,
        estimatedCostCurrency: Currency? = nil,
        notes: String? = nil,
        sortOrder: Int = 0,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.checklistId = checklistId
        self.name = name
        self.isCompleted = isCompleted
        self.dueDate = dueDate
        self.priority = priority
        self.estimatedCost = estimatedCost
        self.estimatedCostCurrency = estimatedCostCurrency
        self.notes = notes
        self.sortOrder = sortOrder
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

    var isDueTomorrow: Bool {
        guard let dueDate = dueDate, !isCompleted else { return false }
        return Calendar.current.isDateInTomorrow(dueDate)
    }

    var formattedEstimatedCost: String? {
        guard let cost = estimatedCost, let currency = estimatedCostCurrency else { return nil }
        return currency.format(cost)
    }
}
