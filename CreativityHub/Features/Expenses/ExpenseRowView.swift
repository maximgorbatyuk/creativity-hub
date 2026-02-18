import SwiftUI

struct ExpenseRowView: View {
    let expense: Expense
    var categoryName: String?

    var body: some View {
        HStack(spacing: 12) {
            statusIcon
            expenseInfo
            Spacer()
            amountInfo
        }
        .padding(.vertical, 4)
    }

    // MARK: - Subviews

    private var statusIcon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(expense.status.color.opacity(0.15))
                .frame(width: 40, height: 40)

            Image(systemName: expense.status.icon)
                .font(.body)
                .foregroundColor(expense.status.color)
        }
    }

    private var expenseInfo: some View {
        VStack(alignment: .leading, spacing: 3) {
            if let vendor = expense.vendor, !vendor.isEmpty {
                Text(vendor)
                    .font(.body)
                    .lineLimit(1)
            }

            HStack(spacing: 6) {
                Text(expense.status.displayName)
                    .font(.caption)
                    .foregroundColor(expense.status.color)

                if let categoryName {
                    Text("·")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(categoryName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Text(expense.date, style: .date)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }

    private var amountInfo: some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text(expense.formattedAmount)
                .font(.body)
                .fontWeight(.semibold)
                .foregroundColor(expense.isPaid ? .primary : .secondary)

            if expense.hasNotes {
                Image(systemName: "note.text")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
}
