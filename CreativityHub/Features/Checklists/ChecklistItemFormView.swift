import SwiftUI

enum ChecklistItemFormMode: Identifiable {
    case add(checklistId: UUID, sortOrder: Int)
    case edit(ChecklistItem)

    var id: String {
        switch self {
        case .add: return "add"
        case .edit(let item): return item.id.uuidString
        }
    }
}

struct ChecklistItemFormView: View {
    let mode: ChecklistItemFormMode
    let defaultCurrency: Currency
    let onSave: (ChecklistItem) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var priority: ItemPriority = .none
    @State private var hasDueDate = false
    @State private var dueDate = Date()
    @State private var hasCost = false
    @State private var costText = ""
    @State private var costCurrency: Currency = .usd
    @State private var notes = ""

    @State private var showValidationError = false
    @State private var validationMessage = ""

    private var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    init(mode: ChecklistItemFormMode, defaultCurrency: Currency = .usd, onSave: @escaping (ChecklistItem) -> Void) {
        self.mode = mode
        self.defaultCurrency = defaultCurrency
        self.onSave = onSave

        if case .edit(let item) = mode {
            _name = State(initialValue: item.name)
            _priority = State(initialValue: item.priority)
            _hasDueDate = State(initialValue: item.dueDate != nil)
            _dueDate = State(initialValue: item.dueDate ?? Date())
            _hasCost = State(initialValue: item.estimatedCost != nil)
            _costText = State(initialValue: item.estimatedCost.map { "\($0)" } ?? "")
            _costCurrency = State(initialValue: item.estimatedCostCurrency ?? defaultCurrency)
            _notes = State(initialValue: item.notes ?? "")
        } else {
            _costCurrency = State(initialValue: defaultCurrency)
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                basicSection
                prioritySection
                dateSection
                costSection
                notesSection
            }
            .navigationTitle(isEditing ? L("checklist_item.form.edit_title") : L("checklist_item.form.add_title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L("button.cancel")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L("button.save")) { saveItem() }
                        .fontWeight(.semibold)
                        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
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

    private var basicSection: some View {
        Section(L("checklist_item.form.section.basic")) {
            TextField(L("checklist_item.form.name"), text: $name)
        }
    }

    private var prioritySection: some View {
        Section(L("checklist_item.form.section.priority")) {
            Picker(L("checklist_item.form.priority"), selection: $priority) {
                ForEach(ItemPriority.allCases) { prio in
                    Label(prio.displayName, systemImage: prio.icon)
                        .tag(prio)
                }
            }
        }
    }

    private var dateSection: some View {
        Section(L("checklist_item.form.section.due_date")) {
            Toggle(L("checklist_item.form.set_due_date"), isOn: $hasDueDate)
            if hasDueDate {
                DatePicker(
                    L("checklist_item.form.due_date"),
                    selection: $dueDate,
                    displayedComponents: .date
                )
            }
        }
    }

    private var costSection: some View {
        Section(L("checklist_item.form.section.cost")) {
            Toggle(L("checklist_item.form.set_cost"), isOn: $hasCost)
            if hasCost {
                HStack {
                    TextField(L("checklist_item.form.cost_amount"), text: $costText)
                        .keyboardType(.decimalPad)
                    Picker("", selection: $costCurrency) {
                        ForEach(Currency.allCases) { currency in
                            Text(currency.shortName).tag(currency)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 90)
                }
            }
        }
    }

    private var notesSection: some View {
        Section(L("checklist_item.form.section.notes")) {
            TextField(L("checklist_item.form.notes_placeholder"), text: $notes, axis: .vertical)
                .lineLimit(3 ... 6)
        }
    }

    // MARK: - Save

    private func saveItem() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            validationMessage = L("checklist_item.form.error.name_required")
            showValidationError = true
            return
        }

        let cost: Decimal? = hasCost ? Decimal(string: costText) : nil
        let currency: Currency? = hasCost ? costCurrency : nil
        let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)

        let item: ChecklistItem
        if case .edit(let existing) = mode {
            item = ChecklistItem(
                id: existing.id,
                checklistId: existing.checklistId,
                name: trimmedName,
                isCompleted: existing.isCompleted,
                dueDate: hasDueDate ? dueDate : nil,
                priority: priority,
                estimatedCost: cost,
                estimatedCostCurrency: currency,
                notes: trimmedNotes.isEmpty ? nil : trimmedNotes,
                sortOrder: existing.sortOrder,
                createdAt: existing.createdAt,
                updatedAt: Date()
            )
        } else if case .add(let checklistId, let sortOrder) = mode {
            item = ChecklistItem(
                checklistId: checklistId,
                name: trimmedName,
                dueDate: hasDueDate ? dueDate : nil,
                priority: priority,
                estimatedCost: cost,
                estimatedCostCurrency: currency,
                notes: trimmedNotes.isEmpty ? nil : trimmedNotes,
                sortOrder: sortOrder
            )
        } else {
            return
        }

        onSave(item)
        dismiss()
    }
}

#Preview {
    ChecklistItemFormView(mode: .add(checklistId: UUID(), sortOrder: 0)) { _ in }
}
