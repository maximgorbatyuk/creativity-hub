import SwiftUI

struct ChecklistsListView: View {
    @State private var viewModel: ChecklistsListViewModel
    @State private var selectedChecklist: Checklist?

    private let projectId: UUID
    private let analytics = AnalyticsService.shared

    init(projectId: UUID) {
        self.projectId = projectId
        _viewModel = State(initialValue: ChecklistsListViewModel(projectId: projectId))
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(spacing: 0) {
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxHeight: .infinity)
                } else if viewModel.checklists.isEmpty {
                    emptyState
                } else {
                    checklistsList
                }
            }

            floatingAddButton
        }
        .navigationTitle(L("checklist.list.title"))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.loadData()
            analytics.trackScreen("checklists_list")
        }
        .refreshable { viewModel.loadData() }
        .sheet(isPresented: $viewModel.showAddSheet) {
            ChecklistFormView { name in
                viewModel.addChecklist(name: name)
            }
        }
        .sheet(item: $viewModel.checklistToEdit) { checklist in
            ChecklistFormView(existingChecklist: checklist) { name in
                viewModel.updateChecklist(id: checklist.id, name: name)
            }
        }
        .navigationDestination(item: $selectedChecklist) { checklist in
            ChecklistDetailView(checklist: checklist, projectId: projectId)
        }
    }

    // MARK: - List

    private var checklistsList: some View {
        List {
            ForEach(viewModel.checklists) { checklist in
                ChecklistRowView(
                    checklist: checklist,
                    progress: viewModel.progress(for: checklist.id)
                )
                .contentShape(Rectangle())
                .onTapGesture {
                    selectedChecklist = checklist
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        viewModel.deleteChecklist(checklist)
                    } label: {
                        Label(L("button.delete"), systemImage: "trash")
                    }

                    Button {
                        viewModel.checklistToEdit = checklist
                    } label: {
                        Label(L("button.edit"), systemImage: "pencil")
                    }
                    .tint(.orange)
                }
            }
            .onMove(perform: viewModel.moveChecklist)
        }
        .listStyle(.plain)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        TypedEmptyStateView(
            type: .checklists,
            actionTitle: L("checklist.list.add")
        ) {
            viewModel.showAddSheet = true
        }
    }

    private var floatingAddButton: some View {
        Button {
            viewModel.showAddSheet = true
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(Color.blue)
                .clipShape(Circle())
                .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 2)
        }
        .padding(.trailing, 20)
        .padding(.bottom, 20)
    }
}
