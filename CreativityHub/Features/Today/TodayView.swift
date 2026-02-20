import SwiftUI

struct TodayView: View {
    @State private var viewModel = TodayViewModel()
    @State private var searchViewModel = SearchViewModel()
    @State private var searchText = ""
    @State private var selectedProject: Project?
    @State private var showUpcomingReminders = false

    private let analytics = AnalyticsService.shared

    private var isSearchActive: Bool {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines).count >= 2
    }

    private var hasNoHomeSections: Bool {
        viewModel.activeProjects.isEmpty
            && !viewModel.hasOverdueItems
            && viewModel.totalReminderCount == 0
    }

    var body: some View {
        NavigationStack {
            Group {
                if isSearchActive {
                    searchContent
                } else {
                    homeContent
                }
            }
            .background(Color(UIColor.systemGroupedBackground))
            .searchable(
                text: $searchText,
                prompt: L("search.placeholder")
            )
            .onChange(of: searchText) { _, newValue in
                searchViewModel.search(query: newValue)
            }
            .navigationTitle(L("tab.home"))
            .onAppear {
                viewModel.loadData()
                analytics.trackScreen("home")
            }
            .refreshable { viewModel.loadData() }
            .navigationDestination(item: $selectedProject) { project in
                ProjectDetailView(project: project)
            }
            .navigationDestination(isPresented: $showUpcomingReminders) {
                UpcomingRemindersView()
            }
        }
    }

    // MARK: - Home Content

    private var homeContent: some View {
        ScrollView {
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxHeight: .infinity)
                    .padding(.top, 100)
            } else {
                VStack(spacing: 16) {
                    statsSection

                    if hasNoHomeSections {
                        emptyState
                    } else {
                        if viewModel.hasOverdueItems {
                            overdueSection
                        }
                        if !viewModel.activeProjects.isEmpty {
                            activeProjectsSection
                        }
                    }
                }
                .padding()
            }
        }
    }

    // MARK: - Search Content

    private var searchContent: some View {
        Group {
            if searchViewModel.isSearching {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if !searchViewModel.hasResults {
                TypedEmptyStateView(type: .searchResults)
            } else {
                searchResults
            }
        }
    }

    private var searchResults: some View {
        List {
            ForEach(searchViewModel.visibleSections) { section in
                Section {
                    switch section {
                    case .projects:
                        ForEach(searchViewModel.projects) { project in
                            searchProjectRow(project)
                        }
                    case .ideas:
                        ForEach(searchViewModel.ideas) { idea in
                            searchIdeaRow(idea)
                        }
                    case .notes:
                        ForEach(searchViewModel.notes) { note in
                            searchNoteRow(note)
                        }
                    case .reminders:
                        ForEach(searchViewModel.reminders) { reminder in
                            searchReminderRow(reminder)
                        }
                    case .expenses:
                        ForEach(searchViewModel.expenses) { expense in
                            searchExpenseRow(expense)
                        }
                    case .checklistItems:
                        ForEach(searchViewModel.checklistItems) { item in
                            searchChecklistItemRow(item)
                        }
                    case .documents:
                        ForEach(searchViewModel.documents) { document in
                            searchDocumentRow(document)
                        }
                    }
                } header: {
                    Label(section.displayName, systemImage: section.icon)
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Search Row Views

    private func searchProjectRow(_ project: Project) -> some View {
        Button {
            selectedProject = project
        } label: {
            HStack(spacing: 10) {
                Image(systemName: project.status.icon)
                    .font(.body)
                    .foregroundColor(project.status.color)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text(project.name)
                        .font(.subheadline)
                        .foregroundColor(.primary)

                    if let desc = project.projectDescription, !desc.isEmpty {
                        Text(desc)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer()

                Text(project.status.displayName)
                    .font(.caption)
                    .foregroundColor(project.status.color)
            }
        }
        .buttonStyle(.plain)
    }

    private func searchIdeaRow(_ idea: Idea) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "lightbulb.fill")
                .font(.body)
                .foregroundColor(.yellow)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(idea.title)
                    .font(.subheadline)
                    .lineLimit(1)

                if let notes = idea.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
        }
    }

    private func searchNoteRow(_ note: Note) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "note.text")
                .font(.body)
                .foregroundColor(.orange)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(note.title)
                    .font(.subheadline)
                    .lineLimit(1)

                if note.hasContent {
                    Text(note.contentPreview)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
        }
    }

    private func searchReminderRow(_ reminder: Reminder) -> some View {
        HStack(spacing: 10) {
            Image(systemName: reminder.isCompleted ? "checkmark.circle.fill" : "bell.fill")
                .font(.body)
                .foregroundColor(reminder.isCompleted ? .green : .blue)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(reminder.title)
                    .font(.subheadline)
                    .strikethrough(reminder.isCompleted)
                    .lineLimit(1)

                if let dueDate = reminder.dueDate {
                    Text(dueDate, style: .date)
                        .font(.caption)
                        .foregroundColor(reminder.isOverdue ? .red : .secondary)
                }
            }
        }
    }

    private func searchExpenseRow(_ expense: Expense) -> some View {
        HStack(spacing: 10) {
            Image(systemName: expense.status.icon)
                .font(.body)
                .foregroundColor(expense.status.color)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                if let vendor = expense.vendor, !vendor.isEmpty {
                    Text(vendor)
                        .font(.subheadline)
                        .lineLimit(1)
                }

                Text(expense.status.displayName)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text(expense.formattedAmount)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }

    private func searchChecklistItemRow(_ item: ChecklistItem) -> some View {
        HStack(spacing: 10) {
            Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                .font(.body)
                .foregroundColor(item.isCompleted ? .green : .secondary)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.subheadline)
                    .strikethrough(item.isCompleted)
                    .lineLimit(1)

                if let dueDate = item.dueDate {
                    Text(dueDate, style: .date)
                        .font(.caption)
                        .foregroundColor(item.isOverdue ? .red : .secondary)
                }
            }

            Spacer()

            if item.priority != .none {
                Label(item.priority.displayName, systemImage: item.priority.icon)
                    .font(.caption)
                    .foregroundColor(item.priority.color)
            }
        }
    }

    private func searchDocumentRow(_ document: Document) -> some View {
        HStack(spacing: 10) {
            Image(systemName: document.fileType.icon)
                .font(.body)
                .foregroundColor(.blue)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(document.displayName)
                    .font(.subheadline)
                    .lineLimit(1)

                Text(document.fileType.displayName)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Stats Section

    private var statsSection: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3),
            spacing: 10
        ) {
            statCard(
                title: L("home.stats.projects"),
                value: "\(viewModel.totalProjectCount)",
                icon: "folder.fill",
                color: .blue
            )

            Button {
                showUpcomingReminders = true
            } label: {
                statCard(
                    title: L("home.stats.reminders"),
                    value: "\(viewModel.totalReminderCount)",
                    icon: "bell.fill",
                    color: .orange
                )
            }
            .buttonStyle(.plain)

            statCard(
                title: L("home.stats.logged_time"),
                value: "-",
                icon: "clock.fill",
                color: .indigo
            )
        }
    }

    private func statCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)

            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
                .lineLimit(1)

            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .cardBackground()
    }

    // MARK: - Overdue Section

    private var overdueSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(L("home.overdue"), systemImage: "exclamationmark.triangle.fill")
                .font(.headline)
                .foregroundColor(.red)

            VStack(spacing: 0) {
                ForEach(viewModel.overdueReminders) { reminder in
                    overdueReminderRow(reminder)
                    if reminder.id != viewModel.overdueReminders.last?.id {
                        Divider().padding(.leading, 40)
                    }
                }

                if !viewModel.overdueChecklistItems.isEmpty && !viewModel.overdueReminders.isEmpty {
                    Divider().padding(.leading, 40)
                }

                ForEach(viewModel.overdueChecklistItems) { item in
                    overdueChecklistRow(item)
                    if item.id != viewModel.overdueChecklistItems.last?.id {
                        Divider().padding(.leading, 40)
                    }
                }
            }
            .padding()
            .cardBackground()
        }
    }

    private func overdueReminderRow(_ reminder: Reminder) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "bell.fill")
                .font(.caption)
                .foregroundColor(.red)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(reminder.title)
                    .font(.subheadline)
                    .lineLimit(1)

                if let projectName = viewModel.projectName(for: reminder) {
                    Text(projectName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            if let dueDate = reminder.dueDate {
                Text(dueDate, style: .date)
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
        .padding(.vertical, 4)
    }

    private func overdueChecklistRow(_ item: ChecklistItem) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle")
                .font(.caption)
                .foregroundColor(.red)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.subheadline)
                    .lineLimit(1)
            }

            Spacer()

            if let dueDate = item.dueDate {
                Text(dueDate, style: .date)
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Active Projects Section

    private var activeProjectsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label(
                    L("home.active_projects", viewModel.activeProjectCount),
                    systemImage: "folder.fill"
                )
                .font(.headline)

                Spacer()
            }

            VStack(spacing: 0) {
                ForEach(viewModel.activeProjects) { project in
                    Button {
                        selectedProject = project
                    } label: {
                        activeProjectRow(project)
                    }
                    .buttonStyle(.plain)

                    if project.id != viewModel.activeProjects.last?.id {
                        Divider().padding(.leading, 52)
                    }
                }
            }
            .padding()
            .cardBackground()
        }
    }

    private func activeProjectRow(_ project: Project) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(projectColor(project).opacity(0.15))
                    .frame(width: 36, height: 36)

                Image(systemName: project.status.icon)
                    .font(.body)
                    .foregroundColor(projectColor(project))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(project.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)

                if let description = project.projectDescription, !description.isEmpty {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "house.fill")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text(L("home.empty.title"))
                .font(.title3)
                .fontWeight(.semibold)

            Text(L("home.empty.message"))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }

    // MARK: - Helpers

    private func projectColor(_ project: Project) -> Color {
        if let colorName = project.coverColor {
            return Color.fromProjectColor(colorName)
        }
        return project.status.color
    }
}
