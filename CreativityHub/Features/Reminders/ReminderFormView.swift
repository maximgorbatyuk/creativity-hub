import SwiftUI

enum ReminderFormMode: Identifiable {
    case add(projectId: UUID)
    case edit(Reminder)

    var id: String {
        switch self {
        case .add: return "add"
        case .edit(let reminder): return reminder.id.uuidString
        }
    }
}

struct ReminderFormView: View {
    let mode: ReminderFormMode
    let onSave: (Reminder) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var notes = ""
    @State private var hasDueDate = false
    @State private var dueDate = Date()
    @State private var priority: ItemPriority = .none

    @State private var showValidationError = false
    @State private var validationMessage = ""

    private var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    init(
        mode: ReminderFormMode,
        onSave: @escaping (Reminder) -> Void
    ) {
        self.mode = mode
        self.onSave = onSave

        if case .edit(let reminder) = mode {
            _title = State(initialValue: reminder.title)
            _notes = State(initialValue: reminder.notes ?? "")
            _hasDueDate = State(initialValue: reminder.dueDate != nil)
            _dueDate = State(initialValue: reminder.dueDate ?? Date())
            _priority = State(initialValue: reminder.priority)
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                titleSection
                prioritySection
                dueDateSection
                notesSection
            }
            .navigationTitle(isEditing ? L("reminder.form.edit_title") : L("reminder.form.add_title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L("button.cancel")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L("button.save")) { saveReminder() }
                        .fontWeight(.semibold)
                }
            }
            .alert(L("error.generic.title"), isPresented: $showValidationError) {
                Button(L("button.done"), role: .cancel) {}
            } message: {
                Text(validationMessage)
            }
        }
    }

    // MARK: - Sections

    private var titleSection: some View {
        Section(L("reminder.form.section.title")) {
            TextField(L("reminder.form.title_placeholder"), text: $title)
        }
    }

    private var prioritySection: some View {
        Section(L("reminder.form.section.priority")) {
            Picker(L("reminder.form.priority"), selection: $priority) {
                ForEach(ItemPriority.allCases) { p in
                    Label(p.displayName, systemImage: p.icon).tag(p)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var dueDateSection: some View {
        Section(L("reminder.form.section.due_date")) {
            Toggle(L("reminder.form.set_due_date"), isOn: $hasDueDate)

            if hasDueDate {
                DatePicker(
                    L("reminder.form.due_date"),
                    selection: $dueDate,
                    displayedComponents: [.date, .hourAndMinute]
                )
            }
        }
    }

    private var notesSection: some View {
        Section(L("reminder.form.section.notes")) {
            TextField(L("reminder.form.notes_placeholder"), text: $notes, axis: .vertical)
                .lineLimit(3 ... 6)
        }
    }

    // MARK: - Save

    private func saveReminder() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else {
            validationMessage = L("reminder.form.error.title_required")
            showValidationError = true
            return
        }

        let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)

        let reminder: Reminder
        if case .edit(let existing) = mode {
            reminder = Reminder(
                id: existing.id,
                projectId: existing.projectId,
                title: trimmedTitle,
                notes: trimmedNotes.isEmpty ? nil : trimmedNotes,
                dueDate: hasDueDate ? dueDate : nil,
                isCompleted: existing.isCompleted,
                priority: priority,
                createdAt: existing.createdAt,
                updatedAt: Date()
            )
        } else if case .add(let projectId) = mode {
            reminder = Reminder(
                projectId: projectId,
                title: trimmedTitle,
                notes: trimmedNotes.isEmpty ? nil : trimmedNotes,
                dueDate: hasDueDate ? dueDate : nil,
                priority: priority
            )
        } else {
            return
        }

        onSave(reminder)
        dismiss()
    }
}
