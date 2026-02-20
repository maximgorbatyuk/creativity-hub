import SwiftUI

enum TagFormMode: Identifiable {
    case add
    case edit(Tag)

    var id: String {
        switch self {
        case .add: return "add"
        case .edit(let tag): return tag.id.uuidString
        }
    }
}

struct TagFormView: View {
    let mode: TagFormMode
    let onSave: (Tag) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var selectedColor = "blue"

    private var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    private let colorOptions = [
        "red", "orange", "yellow", "green", "blue",
        "purple", "pink", "cyan", "mint", "teal",
        "indigo", "brown"
    ]

    init(mode: TagFormMode, onSave: @escaping (Tag) -> Void) {
        self.mode = mode
        self.onSave = onSave

        if case .edit(let tag) = mode {
            _name = State(initialValue: tag.name)
            _selectedColor = State(initialValue: tag.color)
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                nameSection
                colorSection
            }
            .navigationTitle(isEditing ? L("tags.edit") : L("tags.add"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L("button.cancel")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L("button.save")) { saveTag() }
                        .fontWeight(.semibold)
                        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    // MARK: - Sections

    private var nameSection: some View {
        Section(L("tags.name")) {
            TextField(L("tags.name.placeholder"), text: $name)
        }
    }

    private var colorSection: some View {
        Section(L("tags.color")) {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                ForEach(colorOptions, id: \.self) { color in
                    Circle()
                        .fill(colorToSwiftUI(color))
                        .frame(width: 36, height: 36)
                        .overlay {
                            if selectedColor == color {
                                Image(systemName: "checkmark")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            }
                        }
                        .onTapGesture {
                            selectedColor = color
                        }
                }
            }
            .padding(.vertical, 4)
        }
    }

    // MARK: - Save

    private func saveTag() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }

        let tag: Tag
        if case .edit(let existing) = mode {
            tag = Tag(id: existing.id, name: trimmedName, color: selectedColor)
        } else {
            tag = Tag(name: trimmedName, color: selectedColor)
        }

        onSave(tag)
        dismiss()
    }

    // MARK: - Helpers

    private func colorToSwiftUI(_ name: String) -> Color {
        switch name.lowercased() {
        case "red": return .red
        case "orange": return .orange
        case "yellow": return .yellow
        case "green": return .green
        case "blue": return .blue
        case "purple": return .purple
        case "pink": return .pink
        case "cyan": return .cyan
        case "mint": return .mint
        case "teal": return .teal
        case "indigo": return .indigo
        case "brown": return .brown
        default: return .blue
        }
    }
}
