import SwiftUI

struct NotesListView: View {
    @State private var viewModel: NotesListViewModel
    @State private var selectedNote: Note?

    private let projectId: UUID
    private let analytics = AnalyticsService.shared

    init(projectId: UUID) {
        self.projectId = projectId
        _viewModel = State(initialValue: NotesListViewModel(projectId: projectId))
    }

    var body: some View {
        VStack(spacing: 0) {
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxHeight: .infinity)
            } else if viewModel.notes.isEmpty {
                emptyState
            } else {
                sortSection
                listContent
            }
        }
        .navigationTitle(L("note.list.title"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbarContent }
        .onAppear {
            viewModel.loadData()
            analytics.trackScreen("notes_list")
        }
        .refreshable { viewModel.loadData() }
        .sheet(isPresented: $viewModel.showAddSheet) {
            NoteFormView(mode: .add(projectId: projectId)) { note in
                viewModel.addNote(note)
            }
        }
        .sheet(item: $viewModel.noteToEdit) { note in
            NoteFormView(mode: .edit(note)) { updated in
                viewModel.updateNote(updated)
            }
        }
        .navigationDestination(item: $selectedNote) { note in
            NoteDetailView(
                note: note,
                projectId: projectId,
                onUpdate: { viewModel.updateNote($0) },
                onDelete: { viewModel.deleteNote($0) },
                onTogglePin: { viewModel.togglePin($0) }
            )
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Button {
                viewModel.showAddSheet = true
            } label: {
                Image(systemName: "plus")
            }
        }
    }

    // MARK: - Sort

    private var sortSection: some View {
        HStack {
            Text(L("note.list.sort_by"))
                .font(.subheadline)
                .foregroundColor(.secondary)

            Picker(L("note.list.sort_by"), selection: $viewModel.sortOrder) {
                ForEach(NoteSortOrder.allCases, id: \.self) { order in
                    Text(order.displayName).tag(order)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: viewModel.sortOrder) { _, _ in
                viewModel.loadData()
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    // MARK: - List

    private var listContent: some View {
        List {
            ForEach(viewModel.notes) { note in
                NoteRowView(note: note)
                    .contentShape(Rectangle())
                    .onTapGesture { selectedNote = note }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            viewModel.deleteNote(note)
                        } label: {
                            Label(L("button.delete"), systemImage: "trash")
                        }

                        Button {
                            viewModel.noteToEdit = note
                        } label: {
                            Label(L("button.edit"), systemImage: "pencil")
                        }
                        .tint(.orange)
                    }
                    .swipeActions(edge: .leading) {
                        Button {
                            viewModel.togglePin(note)
                        } label: {
                            Label(
                                note.isPinned ? L("note.action.unpin") : L("note.action.pin"),
                                systemImage: note.isPinned ? "pin.slash" : "pin"
                            )
                        }
                        .tint(note.isPinned ? .gray : .orange)
                    }
            }
        }
        .listStyle(.plain)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        TypedEmptyStateView(
            type: .notes,
            actionTitle: L("note.list.add")
        ) {
            viewModel.showAddSheet = true
        }
    }
}
