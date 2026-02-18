import Foundation
import SwiftUI

struct ExpenseCategory: Codable, Identifiable, Equatable, Hashable {
    let id: UUID
    let projectId: UUID
    var name: String
    var budgetLimit: Decimal?
    var budgetCurrency: Currency?
    var color: String
    var sortOrder: Int
    let createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        projectId: UUID,
        name: String,
        budgetLimit: Decimal? = nil,
        budgetCurrency: Currency? = nil,
        color: String = "blue",
        sortOrder: Int = 0,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.projectId = projectId
        self.name = name
        self.budgetLimit = budgetLimit
        self.budgetCurrency = budgetCurrency
        self.color = color
        self.sortOrder = sortOrder
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var hasBudgetLimit: Bool {
        budgetLimit != nil && budgetCurrency != nil
    }

    var formattedBudgetLimit: String? {
        guard let limit = budgetLimit, let currency = budgetCurrency else { return nil }
        return currency.format(limit)
    }

    var swiftUIColor: Color {
        switch color.lowercased() {
        case "red": return .red
        case "orange": return .orange
        case "yellow": return .yellow
        case "green": return .green
        case "blue": return .blue
        case "purple": return .purple
        case "pink": return .pink
        case "cyan": return .cyan
        case "mint": return .mint
        case "teal": return .teal
        case "indigo": return .indigo
        case "brown": return .brown
        default: return .blue
        }
    }
}
