import SwiftUI

enum IdeaFormMode: Identifiable {
    case add(projectId: UUID)
    case edit(Idea)

    var id: String {
        switch self {
        case .add: return "add"
        case .edit(let idea): return idea.id.uuidString
        }
    }
}

struct IdeaFormView: View {
    let mode: IdeaFormMode
    let onSave: (Idea) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var url = ""
    @State private var sourceType: IdeaSourceType = .other
    @State private var notes = ""

    @State private var showValidationError = false
    @State private var validationMessage = ""

    private var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    init(mode: IdeaFormMode, onSave: @escaping (Idea) -> Void) {
        self.mode = mode
        self.onSave = onSave

        if case .edit(let idea) = mode {
            _title = State(initialValue: idea.title)
            _url = State(initialValue: idea.url ?? "")
            _sourceType = State(initialValue: idea.sourceType)
            _notes = State(initialValue: idea.notes ?? "")
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                basicSection
                urlSection
                sourceSection
                notesSection
            }
            .navigationTitle(isEditing ? L("idea.form.edit_title") : L("idea.form.add_title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L("button.cancel")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L("button.save")) { saveIdea() }
                        .fontWeight(.semibold)
                        .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
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
        Section(L("idea.form.section.basic")) {
            TextField(L("idea.form.title"), text: $title)
        }
    }

    private var urlSection: some View {
        Section(L("idea.form.section.url")) {
            TextField(L("idea.form.url_placeholder"), text: $url)
                .keyboardType(.URL)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .onChange(of: url) { _, newValue in
                    if !newValue.isEmpty {
                        sourceType = IdeaSourceType.detect(from: newValue)
                    }
                }

            if !url.isEmpty {
                HStack {
                    Image(systemName: sourceType.icon)
                        .foregroundColor(sourceType.color)
                    Text(L("idea.form.detected_source", sourceType.displayName))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    private var sourceSection: some View {
        Section(L("idea.form.section.source")) {
            Picker(L("idea.form.source_type"), selection: $sourceType) {
                ForEach(IdeaSourceType.allCases) { type in
                    Label(type.displayName, systemImage: type.icon)
                        .tag(type)
                }
            }
        }
    }

    private var notesSection: some View {
        Section(L("idea.form.section.notes")) {
            TextField(L("idea.form.notes_placeholder"), text: $notes, axis: .vertical)
                .lineLimit(3 ... 8)
        }
    }

    // MARK: - Save

    private func saveIdea() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else {
            validationMessage = L("idea.form.error.title_required")
            showValidationError = true
            return
        }

        let trimmedUrl = url.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        let domain = extractDomain(from: trimmedUrl)

        let idea: Idea
        if case .edit(let existing) = mode {
            idea = Idea(
                id: existing.id,
                projectId: existing.projectId,
                url: trimmedUrl.isEmpty ? nil : trimmedUrl,
                title: trimmedTitle,
                thumbnailUrl: existing.thumbnailUrl,
                sourceDomain: domain,
                sourceType: sourceType,
                notes: trimmedNotes.isEmpty ? nil : trimmedNotes,
                createdAt: existing.createdAt,
                updatedAt: Date()
            )
        } else if case .add(let projectId) = mode {
            idea = Idea(
                projectId: projectId,
                url: trimmedUrl.isEmpty ? nil : trimmedUrl,
                title: trimmedTitle,
                sourceDomain: domain,
                sourceType: sourceType,
                notes: trimmedNotes.isEmpty ? nil : trimmedNotes
            )
        } else {
            return
        }

        onSave(idea)
        dismiss()
    }

    private func extractDomain(from urlString: String) -> String? {
        guard !urlString.isEmpty,
              let url = URL(string: urlString),
              let host = url.host
        else { return nil }
        return host.replacingOccurrences(of: "www.", with: "")
    }
}

#Preview {
    IdeaFormView(mode: .add(projectId: UUID())) { _ in }
}
