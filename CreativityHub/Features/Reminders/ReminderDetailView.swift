import SwiftUI

struct ReminderDetailView: View {
    @State private var reminder: Reminder
    @Environment(\.dismiss) private var dismiss

    @State private var showEditSheet = false
    @State private var showDeleteConfirmation = false

    private let onUpdate: (Reminder) -> Void
    private let onDelete: (Reminder) -> Void
    private let onToggleCompleted: (Reminder) -> Void
    private let analytics = AnalyticsService.shared

    init(
        reminder: Reminder,
        onUpdate: @escaping (Reminder) -> Void,
        onDelete: @escaping (Reminder) -> Void,
        onToggleCompleted: @escaping (Reminder) -> Void
    ) {
        _reminder = State(initialValue: reminder)
        self.onUpdate = onUpdate
        self.onDelete = onDelete
        self.onToggleCompleted = onToggleCompleted
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                headerCard
                detailsCard
                if reminder.hasNotes {
                    notesCard
                }
                metadataCard
            }
            .padding()
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationTitle(L("reminder.detail.title"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbarContent }
        .onAppear {
            analytics.trackScreen("reminder_detail")
        }
        .sheet(isPresented: $showEditSheet) {
            ReminderFormView(mode: .edit(reminder)) { updated in
                reminder = updated
                onUpdate(updated)
            }
        }
        .alert(L("reminder.delete.title"), isPresented: $showDeleteConfirmation) {
            Button(L("button.cancel"), role: .cancel) {}
            Button(L("button.delete"), role: .destructive) {
                onDelete(reminder)
                dismiss()
            }
        } message: {
            Text(L("reminder.delete.message"))
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Menu {
                Button {
                    showEditSheet = true
                } label: {
                    Label(L("button.edit"), systemImage: "pencil")
                }

                Button {
                    onToggleCompleted(reminder)
                    reminder.isCompleted.toggle()
                } label: {
                    Label(
                        reminder.isCompleted ? L("reminder.action.mark_pending") : L("reminder.action.mark_completed"),
                        systemImage: reminder.isCompleted ? "circle" : "checkmark.circle.fill"
                    )
                }

                Divider()

                Button(role: .destructive) {
                    showDeleteConfirmation = true
                } label: {
                    Label(L("button.delete"), systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
        }
    }

    // MARK: - Header

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(statusColor.opacity(0.15))
                        .frame(width: 48, height: 48)

                    Image(systemName: reminder.isCompleted ? "checkmark.circle.fill" : "bell.fill")
                        .font(.title3)
                        .foregroundColor(statusColor)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(reminder.title)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .strikethrough(reminder.isCompleted)

                    Text(reminder.isCompleted ? L("reminder.status.completed") : L("reminder.status.pending"))
                        .font(.subheadline)
                        .foregroundColor(statusColor)
                }

                Spacer()
            }
        }
        .padding()
        .cardBackground()
    }

    // MARK: - Details

    private var detailsCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(L("reminder.detail.details"), systemImage: "list.bullet")
                .font(.headline)

            VStack(spacing: 12) {
                if reminder.priority != .none {
                    HStack {
                        Text(L("reminder.detail.priority"))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Label(reminder.priority.displayName, systemImage: reminder.priority.icon)
                            .font(.subheadline)
                            .foregroundColor(reminder.priority.color)
                    }
                }

                if let dueDate = reminder.dueDate {
                    HStack {
                        Text(L("reminder.detail.due_date"))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(dueDate.formatted(date: .long, time: .shortened))
                            .font(.subheadline)
                            .foregroundColor(reminder.isOverdue ? .red : .primary)
                    }
                }
            }
        }
        .padding()
        .cardBackground()
    }

    // MARK: - Notes

    private var notesCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(L("reminder.detail.notes"), systemImage: "note.text")
                .font(.headline)

            Text(reminder.notes ?? "")
                .font(.body)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardBackground()
    }

    // MARK: - Metadata

    private var metadataCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(L("reminder.detail.info"), systemImage: "info.circle")
                .font(.headline)

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(L("reminder.detail.created"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(reminder.createdAt, style: .date)
                        .font(.subheadline)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(L("reminder.detail.updated"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(reminder.updatedAt, style: .date)
                        .font(.subheadline)
                }
            }
        }
        .padding()
        .cardBackground()
    }

    // MARK: - Helpers

    private var statusColor: Color {
        if reminder.isCompleted { return .green }
        if reminder.isOverdue { return .red }
        return .blue
    }
}
