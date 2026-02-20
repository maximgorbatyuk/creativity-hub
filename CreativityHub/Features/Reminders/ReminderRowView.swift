import SwiftUI

struct ReminderRowView: View {
    let reminder: Reminder
    var projectName: String? = nil
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            checkButton
            reminderInfo
            Spacer()
            trailingInfo
        }
        .padding(.vertical, 4)
    }

    // MARK: - Subviews

    private var checkButton: some View {
        Button(action: onToggle) {
            Image(systemName: reminder.isCompleted ? "checkmark.circle.fill" : "circle")
                .font(.title3)
                .foregroundColor(reminder.isCompleted ? .green : .secondary)
        }
        .buttonStyle(.plain)
    }

    private var reminderInfo: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(reminder.title)
                .font(.body)
                .strikethrough(reminder.isCompleted)
                .foregroundColor(reminder.isCompleted ? .secondary : .primary)
                .lineLimit(2)

            if let projectName {
                Text(projectName)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            HStack(spacing: 6) {
                if reminder.priority != .none {
                    Label(reminder.priority.displayName, systemImage: reminder.priority.icon)
                        .font(.caption)
                        .foregroundColor(reminder.priority.color)
                }

                if let dueDate = reminder.dueDate {
                    dueDateLabel(dueDate)
                }
            }
        }
    }

    private var trailingInfo: some View {
        VStack(alignment: .trailing, spacing: 4) {
            toggleButton

            if reminder.isOverdue {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
    }

    private var toggleButton: some View {
        Button(action: onToggle) {
            Text(reminder.isCompleted
                ? L("reminder.action.mark_pending")
                : L("reminder.action.mark_completed"))
                .font(.caption2)
                .fontWeight(.medium)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(reminder.isCompleted ? Color.orange.opacity(0.15) : Color.green.opacity(0.15))
                .foregroundColor(reminder.isCompleted ? .orange : .green)
                .cornerRadius(6)
        }
        .buttonStyle(.plain)
    }

    private func dueDateLabel(_ date: Date) -> some View {
        HStack(spacing: 3) {
            Image(systemName: "calendar")
                .font(.system(size: 9))
            Text(date, style: .date)
                .font(.caption)
        }
        .foregroundColor(dueDateColor(date))
    }

    private func dueDateColor(_ date: Date) -> Color {
        if reminder.isCompleted { return .secondary }
        if reminder.isOverdue { return .red }
        if reminder.isDueToday { return .orange }
        if reminder.isDueSoon { return .yellow }
        return .secondary
    }
}
