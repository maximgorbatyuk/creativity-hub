import Foundation
import SwiftUI

// MARK: - ProjectStatus

enum ProjectStatus: String, Codable, CaseIterable, Identifiable {
    case active
    case completed
    case archived

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .active: return L("project.status.active")
        case .completed: return L("project.status.completed")
        case .archived: return L("project.status.archived")
        }
    }

    var icon: String {
        switch self {
        case .active: return "folder.fill"
        case .completed: return "checkmark.circle.fill"
        case .archived: return "archivebox.fill"
        }
    }

    var color: Color {
        switch self {
        case .active: return .blue
        case .completed: return .green
        case .archived: return .gray
        }
    }
}

// MARK: - Project

struct Project: Codable, Identifiable, Equatable, Hashable {
    let id: UUID
    var name: String
    var projectDescription: String?
    var coverColor: String?
    var coverImagePath: String?
    var status: ProjectStatus
    var startDate: Date?
    var targetDate: Date?
    var budget: Decimal?
    var budgetCurrency: Currency?
    var isPinned: Bool
    var sortOrder: Int
    let createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        projectDescription: String? = nil,
        coverColor: String? = nil,
        coverImagePath: String? = nil,
        status: ProjectStatus = .active,
        startDate: Date? = nil,
        targetDate: Date? = nil,
        budget: Decimal? = nil,
        budgetCurrency: Currency? = nil,
        isPinned: Bool = false,
        sortOrder: Int = 0,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.projectDescription = projectDescription
        self.coverColor = coverColor
        self.coverImagePath = coverImagePath
        self.status = status
        self.startDate = startDate
        self.targetDate = targetDate
        self.budget = budget
        self.budgetCurrency = budgetCurrency
        self.isPinned = isPinned
        self.sortOrder = sortOrder
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var isActive: Bool { status == .active }
    var isCompleted: Bool { status == .completed }
    var isArchived: Bool { status == .archived }

    var hasBudget: Bool {
        budget != nil && budgetCurrency != nil
    }

    var formattedBudget: String? {
        guard let budget = budget, let currency = budgetCurrency else { return nil }
        return currency.format(budget)
    }

    var hasDateRange: Bool {
        startDate != nil || targetDate != nil
    }
}
