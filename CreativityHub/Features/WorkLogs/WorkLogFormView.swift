import SwiftUI

enum WorkLogFormMode: Identifiable {
    case add(projectId: UUID)
    case edit(WorkLog)

    var id: String {
        switch self {
        case .add: return "add"
        case .edit(let workLog): return workLog.id.uuidString
        }
    }
}

struct WorkLogFormView: View {
    let mode: WorkLogFormMode
    let checklistItems: [ChecklistItem]
    let onSave: (WorkLog) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var daysString = ""
    @State private var hoursString = ""
    @State private var minutesString = ""
    @State private var selectedChecklistItemId: UUID?
    @State private var showValidationError = false
    @State private var validationMessage = ""

    private var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    private var projectId: UUID {
        switch mode {
        case .add(let projectId): return projectId
        case .edit(let workLog): return workLog.projectId
        }
    }

    init(
        mode: WorkLogFormMode,
        checklistItems: [ChecklistItem] = [],
        linkedChecklistItemId: UUID? = nil,
        initialTitle: String? = nil,
        onSave: @escaping (WorkLog) -> Void
    ) {
        self.mode = mode
        self.checklistItems = checklistItems
        self.onSave = onSave

        if case .edit(let workLog) = mode {
            let days = workLog.totalMinutes / 1440
            let hours = (workLog.totalMinutes % 1440) / 60
            let minutes = workLog.totalMinutes % 60
            _title = State(initialValue: workLog.title ?? "")
            _daysString = State(initialValue: days > 0 ? "\(days)" : "")
            _hoursString = State(initialValue: hours > 0 ? "\(hours)" : "")
            _minutesString = State(initialValue: minutes > 0 ? "\(minutes)" : "")
            _selectedChecklistItemId = State(initialValue: workLog.linkedChecklistItemId)
        } else {
            _title = State(initialValue: initialTitle ?? "")
            _selectedChecklistItemId = State(initialValue: linkedChecklistItemId)
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                titleSection
                durationSection
                if !checklistItems.isEmpty {
                    checklistItemSection
                }
            }
            .navigationTitle(isEditing ? L("worklog.form.edit_title") : L("worklog.form.add_title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L("button.cancel")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L("button.save")) { saveWorkLog() }
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
        Section {
            TextField(L("worklog.form.title_placeholder"), text: $title)
        } header: {
            Text(L("worklog.form.title"))
        }
    }

    private var durationSection: some View {
        Section {
            HStack {
                Text(L("worklog.form.days"))
                Spacer()
                TextField("0", text: $daysString)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 80)
            }
            HStack {
                Text(L("worklog.form.hours"))
                Spacer()
                TextField("0", text: $hoursString)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 80)
            }
            HStack {
                Text(L("worklog.form.minutes"))
                Spacer()
                TextField("0", text: $minutesString)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 80)
            }
        }
    }

    private var checklistItemSection: some View {
        Section {
            Picker(L("worklog.form.linked_item"), selection: $selectedChecklistItemId) {
                Text(L("worklog.form.linked_item.none")).tag(nil as UUID?)
                ForEach(checklistItems) { item in
                    Text(item.name).tag(item.id as UUID?)
                }
            }
        }
    }

    // MARK: - Save

    private func saveWorkLog() {
        let days = Int(daysString) ?? 0
        let hours = Int(hoursString) ?? 0
        let minutes = Int(minutesString) ?? 0

        if days < 0 || hours < 0 || minutes < 0 {
            validationMessage = L("worklog.form.error.negative_values")
            showValidationError = true
            return
        }

        let totalMinutes = days * 1440 + hours * 60 + minutes
        if totalMinutes <= 0 {
            validationMessage = L("worklog.form.error.total_zero")
            showValidationError = true
            return
        }

        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let workLogTitle: String? = trimmedTitle.isEmpty ? nil : trimmedTitle

        let workLog: WorkLog
        if case .edit(let existing) = mode {
            workLog = WorkLog(
                id: existing.id,
                projectId: existing.projectId,
                title: workLogTitle,
                linkedChecklistItemId: selectedChecklistItemId,
                totalMinutes: totalMinutes,
                createdAt: existing.createdAt,
                updatedAt: Date()
            )
        } else {
            workLog = WorkLog(
                projectId: projectId,
                title: workLogTitle,
                linkedChecklistItemId: selectedChecklistItemId,
                totalMinutes: totalMinutes
            )
        }

        onSave(workLog)
        dismiss()
    }
}
