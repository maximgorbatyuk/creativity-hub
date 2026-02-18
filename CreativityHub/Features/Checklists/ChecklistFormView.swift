import SwiftUI

struct ChecklistFormView: View {
    let existingChecklist: Checklist?
    let onSave: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @FocusState private var isNameFocused: Bool

    init(existingChecklist: Checklist? = nil, onSave: @escaping (String) -> Void) {
        self.existingChecklist = existingChecklist
        self.onSave = onSave
        _name = State(initialValue: existingChecklist?.name ?? "")
    }

    private var isEditing: Bool { existingChecklist != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(L("checklist.form.name_placeholder"), text: $name)
                        .focused($isNameFocused)
                } header: {
                    Text(L("checklist.form.name"))
                }
            }
            .navigationTitle(isEditing ? L("checklist.form.edit_title") : L("checklist.form.add_title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L("button.cancel")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L("button.save")) {
                        onSave(name.trimmingCharacters(in: .whitespacesAndNewlines))
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear {
                isNameFocused = true
            }
        }
    }
}

#Preview {
    ChecklistFormView { _ in }
}
