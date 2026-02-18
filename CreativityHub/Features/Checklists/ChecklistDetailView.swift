import SwiftUI

struct ChecklistDetailView: View {
    @State private var viewModel: ChecklistDetailViewModel
    @Environment(\.dismiss) private var dismiss

    private let analytics = AnalyticsService.shared

    init(checklist: Checklist, projectId: UUID) {
        _viewModel = State(initialValue: ChecklistDetailViewModel(
            checklist: checklist,
            projectId: projectId
        ))
    }

    var body: some View {
        VStack(spacing: 0) {
            if viewModel.progress.total > 0 {
                progressHeader
            }
            filterSection
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxHeight: .infinity)
            } else if viewModel.filteredItems.isEmpty {
                emptyState
            } else {
                itemsList
            }
        }
        .navigationTitle(viewModel.checklist.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    viewModel.showAddItemSheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .onAppear {
            viewModel.loadData()
            analytics.trackScreen("checklist_detail")
        }
        .refreshable { viewModel.loadData() }
        .sheet(isPresented: $viewModel.showAddItemSheet) {
            ChecklistItemFormView(
                mode: .add(checklistId: viewModel.checklist.id, sortOrder: viewModel.nextSortOrder)
            ) { item in
                viewModel.addItem(item)
            }
        }
        .sheet(item: $viewModel.itemToEdit) { item in
            ChecklistItemFormView(mode: .edit(item)) { updated in
                viewModel.updateItem(updated)
            }
        }
    }

    // MARK: - Progress Header

    private var progressHeader: some View {
        VStack(spacing: 6) {
            HStack {
                Text(L("checklist.detail.progress"))
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                Text("\(viewModel.progress.checked)/\(viewModel.progress.total)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            ProgressView(value: viewModel.progressPercentage)
                .tint(viewModel.progressPercentage == 1.0 ? .green : .accentColor)
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(Color(UIColor.systemGroupedBackground))
    }

    // MARK: - Filter

    private var filterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(ChecklistItemFilter.allCases, id: \.self) { filter in
                    FilterChip(
                        title: filter.displayName,
                        isSelected: viewModel.selectedFilter == filter
                    ) {
                        viewModel.selectedFilter = filter
                        viewModel.applyFilter()
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }

    // MARK: - List

    private var itemsList: some View {
        List {
            ForEach(viewModel.filteredItems) { item in
                ChecklistItemRowView(item: item) {
                    viewModel.toggleItemCompletion(item)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        viewModel.deleteItem(item)
                    } label: {
                        Label(L("button.delete"), systemImage: "trash")
                    }

                    Button {
                        viewModel.itemToEdit = item
                    } label: {
                        Label(L("button.edit"), systemImage: "pencil")
                    }
                    .tint(.orange)
                }
            }
            .onMove(perform: moveHandler)
        }
        .listStyle(.plain)
    }

    private var moveHandler: ((IndexSet, Int) -> Void)? {
        guard viewModel.selectedFilter == .all else { return nil }
        return { source, destination in
            viewModel.moveItem(from: source, to: destination)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        TypedEmptyStateView(
            type: .checklistItems,
            actionTitle: L("checklist.detail.add_item")
        ) {
            viewModel.showAddItemSheet = true
        }
    }
}
