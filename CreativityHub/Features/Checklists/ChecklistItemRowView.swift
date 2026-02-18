import SwiftUI

struct ChecklistItemRowView: View {
    let item: ChecklistItem
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            toggleButton
            itemInfo
            Spacer()
            trailingInfo
        }
        .padding(.vertical, 2)
    }

    // MARK: - Subviews

    private var toggleButton: some View {
        Button(action: onToggle) {
            Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                .font(.title3)
                .foregroundColor(item.isCompleted ? .green : .secondary)
        }
        .buttonStyle(.plain)
    }

    private var itemInfo: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(item.name)
                .font(.body)
                .strikethrough(item.isCompleted)
                .foregroundColor(item.isCompleted ? .secondary : .primary)
                .lineLimit(2)

            HStack(spacing: 8) {
                if item.priority != .none {
                    priorityBadge
                }
                if let dueDate = item.dueDate {
                    dueDateLabel(dueDate)
                }
                if let cost = item.formattedEstimatedCost {
                    costLabel(cost)
                }
            }
        }
    }

    private var trailingInfo: some View {
        Group {
            if item.notes != nil {
                Image(systemName: "note.text")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    private var priorityBadge: some View {
        Label(item.priority.displayName, systemImage: item.priority.icon)
            .font(.caption2)
            .foregroundColor(item.priority.color)
    }

    private func dueDateLabel(_ date: Date) -> some View {
        Label {
            Text(date, style: .date)
                .font(.caption2)
        } icon: {
            Image(systemName: "calendar")
                .font(.caption2)
        }
        .foregroundColor(item.isOverdue ? .red : .secondary)
    }

    private func costLabel(_ cost: String) -> some View {
        Label(cost, systemImage: "banknote")
            .font(.caption2)
            .foregroundColor(.secondary)
    }
}
