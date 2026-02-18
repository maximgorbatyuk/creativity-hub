import SwiftUI

struct SearchView: View {
    @State private var viewModel = SearchViewModel()
    @State private var searchText = ""
    @State private var selectedProject: Project?

    private let analytics = AnalyticsService.shared

    var body: some View {
        NavigationStack {
            Group {
                if searchText.trimmingCharacters(in: .whitespacesAndNewlines).count < 2 {
                    searchPrompt
                } else if viewModel.isSearching {
                    ProgressView()
                        .frame(maxHeight: .infinity)
                } else if !viewModel.hasResults {
                    TypedEmptyStateView(type: .searchResults)
                } else {
                    searchResults
                }
            }
            .searchable(
                text: $searchText,
                prompt: L("search.placeholder")
            )
            .onChange(of: searchText) { _, newValue in
                viewModel.search(query: newValue)
            }
            .navigationTitle(L("tab.search"))
            .onAppear {
                analytics.trackScreen("search")
            }
            .navigationDestination(item: $selectedProject) { project in
                ProjectDetailView(project: project)
            }
        }
    }

    // MARK: - Search Prompt

    private var searchPrompt: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            Text(L("search.prompt"))
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Results

    private var searchResults: some View {
        List {
            ForEach(viewModel.visibleSections) { section in
                Section {
                    switch section {
                    case .projects:
                        ForEach(viewModel.projects) { project in
                            projectRow(project)
                        }
                    case .ideas:
                        ForEach(viewModel.ideas) { idea in
                            ideaRow(idea)
                        }
                    case .notes:
                        ForEach(viewModel.notes) { note in
                            noteRow(note)
                        }
                    case .reminders:
                        ForEach(viewModel.reminders) { reminder in
                            reminderRow(reminder)
                        }
                    case .expenses:
                        ForEach(viewModel.expenses) { expense in
                            expenseRow(expense)
                        }
                    case .checklistItems:
                        ForEach(viewModel.checklistItems) { item in
                            checklistItemRow(item)
                        }
                    }
                } header: {
                    Label(section.displayName, systemImage: section.icon)
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Row Views

    private func projectRow(_ project: Project) -> some View {
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

    private func ideaRow(_ idea: Idea) -> some View {
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

    private func noteRow(_ note: Note) -> some View {
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

    private func reminderRow(_ reminder: Reminder) -> some View {
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

    private func expenseRow(_ expense: Expense) -> some View {
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

    private func checklistItemRow(_ item: ChecklistItem) -> some View {
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
}
