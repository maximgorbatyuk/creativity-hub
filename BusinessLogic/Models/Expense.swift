import Foundation
import SwiftUI

// MARK: - ExpenseStatus

enum ExpenseStatus: String, Codable, CaseIterable, Identifiable {
    case planned
    case paid
    case refunded

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .planned: return L("expense.status.planned")
        case .paid: return L("expense.status.paid")
        case .refunded: return L("expense.status.refunded")
        }
    }

    var icon: String {
        switch self {
        case .planned: return "clock.fill"
        case .paid: return "checkmark.circle.fill"
        case .refunded: return "arrow.uturn.backward.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .planned: return .orange
        case .paid: return .green
        case .refunded: return .blue
        }
    }
}

// MARK: - Expense

struct Expense: Codable, Identifiable, Equatable {
    let id: UUID
    let projectId: UUID
    var categoryId: UUID?
    var amount: Decimal
    var currency: Currency
    var date: Date
    var vendor: String?
    var status: ExpenseStatus
    var receiptImagePath: String?
    var notes: String?
    var linkedChecklistItemId: UUID?
    let createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        projectId: UUID,
        categoryId: UUID? = nil,
        amount: Decimal,
        currency: Currency,
        date: Date = Date(),
        vendor: String? = nil,
        status: ExpenseStatus = .planned,
        receiptImagePath: String? = nil,
        notes: String? = nil,
        linkedChecklistItemId: UUID? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.projectId = projectId
        self.categoryId = categoryId
        self.amount = amount
        self.currency = currency
        self.date = date
        self.vendor = vendor
        self.status = status
        self.receiptImagePath = receiptImagePath
        self.notes = notes
        self.linkedChecklistItemId = linkedChecklistItemId
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var formattedAmount: String {
        currency.format(amount)
    }

    var isPaid: Bool { status == .paid }
    var isPlanned: Bool { status == .planned }
    var isRefunded: Bool { status == .refunded }

    var hasReceipt: Bool {
        guard let path = receiptImagePath else { return false }
        return !path.isEmpty
    }

    var hasNotes: Bool {
        guard let notes = notes else { return false }
        return !notes.isEmpty
    }
}
