import SwiftUI

enum NoteFormMode: Identifiable {
    case add(projectId: UUID)
    case edit(Note)

    var id: String {
        switch self {
        case .add: return "add"
        case .edit(let note): return note.id.uuidString
        }
    }
}

struct NoteFormView: View {
    let mode: NoteFormMode
    let onSave: (Note) -> Void

    @Environment(\.dismiss) private var dismiss
    @FocusState private var titleFocused: Bool

    @State private var title = ""
    @State private var content = ""

    @State private var showValidationError = false
    @State private var validationMessage = ""

    private var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    init(mode: NoteFormMode, onSave: @escaping (Note) -> Void) {
        self.mode = mode
        self.onSave = onSave

        if case .edit(let note) = mode {
            _title = State(initialValue: note.title)
            _content = State(initialValue: note.content)
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(L("note.form.section.title")) {
                    TextField(L("note.form.title_placeholder"), text: $title)
                        .focused($titleFocused)
                }

                Section(L("note.form.section.content")) {
                    TextField(L("note.form.content_placeholder"), text: $content, axis: .vertical)
                        .lineLimit(5 ... 15)
                }
            }
            .navigationTitle(isEditing ? L("note.form.edit_title") : L("note.form.add_title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L("button.cancel")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L("button.save")) { saveNote() }
                        .fontWeight(.semibold)
                        .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .alert(L("error.generic.title"), isPresented: $showValidationError) {
                Button(L("button.done"), role: .cancel) {}
            } message: {
                Text(validationMessage)
            }
            .onAppear {
                if !isEditing {
                    titleFocused = true
                }
            }
        }
    }

    // MARK: - Save

    private func saveNote() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else {
            validationMessage = L("note.form.error.title_required")
            showValidationError = true
            return
        }

        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)

        let note: Note
        if case .edit(let existing) = mode {
            note = Note(
                id: existing.id,
                projectId: existing.projectId,
                title: trimmedTitle,
                content: trimmedContent,
                isPinned: existing.isPinned,
                sortOrder: existing.sortOrder,
                createdAt: existing.createdAt,
                updatedAt: Date()
            )
        } else if case .add(let projectId) = mode {
            note = Note(
                projectId: projectId,
                title: trimmedTitle,
                content: trimmedContent
            )
        } else {
            return
        }

        onSave(note)
        dismiss()
    }
}

#Preview {
    NoteFormView(mode: .add(projectId: UUID())) { _ in }
}
