import SwiftUI

struct NoteDetailView: View {
    @State private var note: Note
    @Environment(\.dismiss) private var dismiss

    @State private var showEditSheet = false
    @State private var showDeleteConfirmation = false

    private let projectId: UUID
    private let onUpdate: (Note) -> Void
    private let onDelete: (Note) -> Void
    private let onTogglePin: (Note) -> Void
    private let analytics = AnalyticsService.shared

    init(
        note: Note,
        projectId: UUID,
        onUpdate: @escaping (Note) -> Void,
        onDelete: @escaping (Note) -> Void,
        onTogglePin: @escaping (Note) -> Void
    ) {
        _note = State(initialValue: note)
        self.projectId = projectId
        self.onUpdate = onUpdate
        self.onDelete = onDelete
        self.onTogglePin = onTogglePin
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                headerCard
                if note.hasContent {
                    contentCard
                }
                metadataCard
            }
            .padding()
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationTitle(L("note.detail.title"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbarContent }
        .onAppear {
            analytics.trackScreen("note_detail")
        }
        .sheet(isPresented: $showEditSheet) {
            NoteFormView(mode: .edit(note)) { updated in
                note = updated
                onUpdate(updated)
            }
        }
        .alert(L("note.delete.title"), isPresented: $showDeleteConfirmation) {
            Button(L("button.cancel"), role: .cancel) {}
            Button(L("button.delete"), role: .destructive) {
                onDelete(note)
                dismiss()
            }
        } message: {
            Text(L("note.delete.message"))
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
                    onTogglePin(note)
                    note.isPinned.toggle()
                } label: {
                    Label(
                        note.isPinned ? L("note.action.unpin") : L("note.action.pin"),
                        systemImage: note.isPinned ? "pin.slash" : "pin"
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
                        .fill(Color.orange.opacity(0.15))
                        .frame(width: 48, height: 48)

                    Image(systemName: "note.text")
                        .font(.title3)
                        .foregroundColor(.orange)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        if note.isPinned {
                            Image(systemName: "pin.fill")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                        Text(note.title)
                            .font(.title3)
                            .fontWeight(.semibold)
                    }

                    Text(note.updatedAt, style: .date)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
        }
        .padding()
        .cardBackground()
    }

    // MARK: - Content

    private var contentCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(L("note.detail.content"), systemImage: "doc.text")
                .font(.headline)

            Text(note.content)
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
            Label(L("note.detail.info"), systemImage: "info.circle")
                .font(.headline)

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(L("note.detail.created"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(note.createdAt, style: .date)
                        .font(.subheadline)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(L("note.detail.updated"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(note.updatedAt, style: .date)
                        .font(.subheadline)
                }
            }
        }
        .padding()
        .cardBackground()
    }
}
