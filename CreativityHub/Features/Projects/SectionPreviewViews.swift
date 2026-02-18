import SwiftUI

// MARK: - Checklist Preview Row

struct ChecklistPreviewRow: View {
    let checklist: Checklist
    let progress: (checked: Int, total: Int)

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checklist")
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 32, height: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(checklist.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    ProgressView(value: progressPercentage)
                        .tint(progressColor)
                        .frame(width: 60)

                    Text("\(progress.checked)/\(progress.total)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            Text("\(Int(progressPercentage * 100))%")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(progressColor)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    private var progressPercentage: Double {
        guard progress.total > 0 else { return 0 }
        return Double(progress.checked) / Double(progress.total)
    }

    private var progressColor: Color {
        if progress.total == 0 {
            return .gray
        } else if progress.checked == progress.total {
            return .green
        } else if progressPercentage > 0.5 {
            return .blue
        } else {
            return .orange
        }
    }
}

// MARK: - Idea Preview Row

struct IdeaPreviewRow: View {
    let idea: Idea

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: idea.sourceType.icon)
                .font(.title3)
                .foregroundColor(idea.sourceType.color)
                .frame(width: 32, height: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(idea.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)

                if let url = idea.url, !url.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "link")
                            .font(.caption2)
                        Text(idea.sourceDomain ?? url)
                            .lineLimit(1)
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                } else if let notes = idea.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

// MARK: - Note Preview Row

struct NotePreviewRow: View {
    let note: Note

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "note.text")
                .font(.title3)
                .foregroundColor(.orange)
                .frame(width: 32, height: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(note.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)

                if note.hasContent {
                    Text(note.contentPreview)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }

            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

// MARK: - Document Preview Row

struct DocumentPreviewRow: View {
    let document: Document

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: document.fileType.icon)
                .font(.title3)
                .foregroundColor(.purple)
                .frame(width: 32, height: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(document.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Text(document.fileType.displayName)
                    Text("•")
                    Text(document.formattedFileSize)
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

// MARK: - Expense Preview Row

struct ExpensePreviewRow: View {
    let expense: Expense

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: expense.status.icon)
                .font(.title3)
                .foregroundColor(expense.status.color)
                .frame(width: 32, height: 32)

            VStack(alignment: .leading, spacing: 4) {
                if let vendor = expense.vendor, !vendor.isEmpty {
                    Text(vendor)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(1)
                }

                HStack(spacing: 4) {
                    Text(expense.status.displayName)
                    Text("•")
                    Text(formatDate(expense.date))
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }

            Spacer()

            Text(expense.formattedAmount)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}

// MARK: - Reminder Preview Row

struct ReminderPreviewRow: View {
    let reminder: Reminder

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: reminder.isCompleted ? "checkmark.circle.fill" : "bell.fill")
                .font(.title3)
                .foregroundColor(reminderColor)
                .frame(width: 32, height: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(reminder.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                    .strikethrough(reminder.isCompleted)

                if let dueDate = reminder.dueDate {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.caption2)
                        Text(formatDateTime(dueDate))
                    }
                    .font(.caption)
                    .foregroundColor(reminder.isOverdue ? .red : .secondary)
                }
            }

            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    private var reminderColor: Color {
        if reminder.isCompleted { return .green }
        if reminder.isOverdue { return .red }
        return .blue
    }

    private func formatDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, HH:mm"
        return formatter.string(from: date)
    }
}

// MARK: - Empty Section View

struct EmptySectionView: View {
    let message: String
    let iconName: String

    var body: some View {
        HStack {
            Spacer()
            VStack(spacing: 8) {
                Image(systemName: iconName)
                    .font(.title2)
                    .foregroundColor(.gray.opacity(0.5))
                Text(message)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 20)
            Spacer()
        }
    }
}
