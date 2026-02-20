import SwiftUI

struct IdeasListView: View {
    @State private var viewModel: IdeasListViewModel
    @State private var selectedIdea: Idea?

    private let projectId: UUID
    private let analytics = AnalyticsService.shared

    private let gridColumns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    init(projectId: UUID) {
        self.projectId = projectId
        _viewModel = State(initialValue: IdeasListViewModel(projectId: projectId))
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(spacing: 0) {
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxHeight: .infinity)
                } else if viewModel.ideas.isEmpty {
                    emptyState
                } else {
                    filterSection
                    if viewModel.filteredIdeas.isEmpty {
                        filterEmptyState
                    } else if viewModel.layout == .list {
                        listContent
                    } else {
                        gridContent
                    }
                }
            }

            floatingAddButton
        }
        .navigationTitle(L("idea.list.title"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbarContent }
        .onAppear {
            viewModel.loadData()
            analytics.trackScreen("ideas_list")
        }
        .refreshable { viewModel.loadData() }
        .sheet(isPresented: $viewModel.showAddSheet) {
            IdeaFormView(mode: .add(projectId: projectId)) { idea in
                viewModel.addIdea(idea)
            }
        }
        .sheet(item: $viewModel.ideaToEdit) { idea in
            IdeaFormView(mode: .edit(idea)) { updated in
                viewModel.updateIdea(updated)
            }
        }
        .navigationDestination(item: $selectedIdea) { idea in
            IdeaDetailView(idea: idea, projectId: projectId)
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Button {
                withAnimation {
                    viewModel.layout = viewModel.layout == .list ? .grid : .list
                }
            } label: {
                Image(systemName: viewModel.layout == .list ? "square.grid.2x2" : "list.bullet")
            }
        }
    }

    // MARK: - Filter

    private var filterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(
                    title: L("idea.filter.all"),
                    isSelected: viewModel.selectedFilter == .all
                ) {
                    viewModel.selectedFilter = .all
                    viewModel.applyFilter()
                }

                ForEach(viewModel.availableSourceTypes) { sourceType in
                    FilterChip(
                        title: sourceType.displayName,
                        isSelected: viewModel.selectedFilter == .source(sourceType)
                    ) {
                        viewModel.selectedFilter = .source(sourceType)
                        viewModel.applyFilter()
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }

    // MARK: - List

    private var listContent: some View {
        List {
            ForEach(viewModel.filteredIdeas) { idea in
                IdeaRowView(idea: idea)
                    .contentShape(Rectangle())
                    .onTapGesture { selectedIdea = idea }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            viewModel.deleteIdea(idea)
                        } label: {
                            Label(L("button.delete"), systemImage: "trash")
                        }

                        Button {
                            viewModel.ideaToEdit = idea
                        } label: {
                            Label(L("button.edit"), systemImage: "pencil")
                        }
                        .tint(.orange)
                    }
            }
        }
        .listStyle(.plain)
    }

    // MARK: - Grid

    private var gridContent: some View {
        ScrollView {
            LazyVGrid(columns: gridColumns, spacing: 12) {
                ForEach(viewModel.filteredIdeas) { idea in
                    IdeaGridItemView(idea: idea)
                        .onTapGesture { selectedIdea = idea }
                        .contextMenu {
                            Button {
                                viewModel.ideaToEdit = idea
                            } label: {
                                Label(L("button.edit"), systemImage: "pencil")
                            }

                            Button(role: .destructive) {
                                viewModel.deleteIdea(idea)
                            } label: {
                                Label(L("button.delete"), systemImage: "trash")
                            }
                        }
                }
            }
            .padding()
        }
    }

    // MARK: - Empty States

    private var emptyState: some View {
        TypedEmptyStateView(
            type: .ideas,
            actionTitle: L("idea.list.add")
        ) {
            viewModel.showAddSheet = true
        }
    }

    private var filterEmptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "lightbulb")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            Text(L("idea.filter.no_results"))
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var floatingAddButton: some View {
        Button {
            viewModel.showAddSheet = true
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(Color.yellow)
                .clipShape(Circle())
                .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 2)
        }
        .padding(.trailing, 20)
        .padding(.bottom, 20)
    }
}
