import SwiftUI

struct ProjectsListView: View {
    @State private var viewModel = ProjectsListViewModel()
    @State private var selectedProject: Project?

    private let analytics = AnalyticsService.shared

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                VStack(spacing: 0) {
                    if viewModel.isLoading {
                        ProgressView()
                            .frame(maxHeight: .infinity)
                    } else if viewModel.filteredProjects.isEmpty {
                        emptyStateView
                    } else {
                        projectsList
                    }
                }
                .safeAreaInset(edge: .top, spacing: 0) {
                    filterSection
                }

                floatingAddButton
            }
            .navigationTitle(L("tab.projects"))
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                viewModel.loadProjects()
                analytics.trackScreen("projects_list")
            }
            .refreshable { viewModel.loadProjects() }
            .sheet(isPresented: $viewModel.showAddSheet) {
                ProjectFormView(mode: .add) { project in
                    viewModel.addProject(project)
                }
            }
            .sheet(item: $viewModel.projectToEdit) { project in
                ProjectFormView(mode: .edit(project)) { updated in
                    viewModel.updateProject(updated)
                }
            }
            .navigationDestination(item: $selectedProject) { project in
                ProjectDetailView(project: project)
            }
        }
    }

    // MARK: - Filter

    private var filterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(ProjectFilter.allCases, id: \.self) { filter in
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
        .frame(height: 52)
        .background(Color(UIColor.systemBackground))
        .overlay(alignment: .bottom) {
            Divider()
        }
    }

    // MARK: - List

    private var projectsList: some View {
        List {
            ForEach(viewModel.filteredProjects) { project in
                ProjectRowView(project: project, stats: viewModel.stats(for: project))
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedProject = project
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            viewModel.deleteProject(project)
                        } label: {
                            Label(L("button.delete"), systemImage: "trash")
                        }

                        Button {
                            viewModel.projectToEdit = project
                        } label: {
                            Label(L("button.edit"), systemImage: "pencil")
                        }
                        .tint(.orange)
                    }
                    .swipeActions(edge: .leading) {
                        Button {
                            viewModel.togglePin(project)
                        } label: {
                            Label(
                                project.isPinned ? L("project.action.unpin") : L("project.action.pin"),
                                systemImage: project.isPinned ? "pin.slash.fill" : "pin.fill"
                            )
                        }
                        .tint(project.isPinned ? .gray : .orange)
                    }
            }
        }
        .listStyle(.plain)
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        TypedEmptyStateView(
            type: .projects,
            actionTitle: L("projects.new")
        ) {
            viewModel.showAddSheet = true
        }
    }

    // MARK: - FAB

    private var floatingAddButton: some View {
        Button {
            viewModel.showAddSheet = true
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(Color.accentColor)
                .clipShape(Circle())
                .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 2)
        }
        .padding(.trailing, 20)
        .padding(.bottom, 20)
    }
}

#Preview {
    ProjectsListView()
}
