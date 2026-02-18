import SwiftUI

struct TodayView: View {
    @State private var viewModel = TodayViewModel()
    @State private var selectedProject: Project?

    private let analytics = AnalyticsService.shared

    var body: some View {
        NavigationStack {
            ScrollView {
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxHeight: .infinity)
                        .padding(.top, 100)
                } else if viewModel.activeProjects.isEmpty && !viewModel.hasOverdueItems && !viewModel.hasUpcomingReminders {
                    emptyState
                } else {
                    VStack(spacing: 16) {
                        if viewModel.hasOverdueItems {
                            overdueSection
                        }
                        if viewModel.hasUpcomingReminders {
                            remindersSection
                        }
                        if !viewModel.activeProjects.isEmpty {
                            activeProjectsSection
                        }
                    }
                    .padding()
                }
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle(L("tab.today"))
            .onAppear {
                viewModel.loadData()
                analytics.trackScreen("today")
            }
            .refreshable { viewModel.loadData() }
            .navigationDestination(item: $selectedProject) { project in
                ProjectDetailView(project: project)
            }
        }
    }

    // MARK: - Overdue Section

    private var overdueSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(L("today.overdue"), systemImage: "exclamationmark.triangle.fill")
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

    // MARK: - Reminders Section

    private var remindersSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(L("today.upcoming_reminders"), systemImage: "bell.fill")
                .font(.headline)

            VStack(spacing: 0) {
                ForEach(viewModel.upcomingReminders) { reminder in
                    upcomingReminderRow(reminder)
                    if reminder.id != viewModel.upcomingReminders.last?.id {
                        Divider().padding(.leading, 40)
                    }
                }
            }
            .padding()
            .cardBackground()
        }
    }

    private func upcomingReminderRow(_ reminder: Reminder) -> some View {
        HStack(spacing: 10) {
            Image(systemName: reminder.priority != .none ? reminder.priority.icon : "bell")
                .font(.caption)
                .foregroundColor(reminder.priority != .none ? reminder.priority.color : .blue)
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
                    .foregroundColor(reminder.isDueSoon ? .orange : .secondary)
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Active Projects Section

    private var activeProjectsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label(
                    L("today.active_projects", viewModel.activeProjectCount),
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
            Image(systemName: "sun.max.fill")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text(L("today.empty.title"))
                .font(.title3)
                .fontWeight(.semibold)

            Text(L("today.empty.message"))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 100)
    }

    // MARK: - Helpers

    private func projectColor(_ project: Project) -> Color {
        if let colorName = project.coverColor {
            return Color.fromProjectColor(colorName)
        }
        return project.status.color
    }
}
