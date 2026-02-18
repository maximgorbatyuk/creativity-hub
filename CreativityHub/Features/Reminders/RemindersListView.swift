import SwiftUI

struct RemindersListView: View {
    @State private var viewModel: RemindersListViewModel
    @State private var selectedReminder: Reminder?

    private let projectId: UUID
    private let analytics = AnalyticsService.shared

    init(projectId: UUID) {
        self.projectId = projectId
        _viewModel = State(initialValue: RemindersListViewModel(projectId: projectId))
    }

    var body: some View {
        VStack(spacing: 0) {
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxHeight: .infinity)
            } else if viewModel.reminders.isEmpty {
                emptyState
            } else {
                filterSection
                summaryBar
                if viewModel.filteredReminders.isEmpty {
                    filterEmptyState
                } else {
                    listContent
                }
            }
        }
        .navigationTitle(L("reminder.list.title"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbarContent }
        .onAppear {
            viewModel.loadData()
            analytics.trackScreen("reminders_list")
        }
        .refreshable { viewModel.loadData() }
        .sheet(isPresented: $viewModel.showAddSheet) {
            ReminderFormView(mode: .add(projectId: projectId)) { reminder in
                viewModel.addReminder(reminder)
            }
        }
        .sheet(item: $viewModel.reminderToEdit) { reminder in
            ReminderFormView(mode: .edit(reminder)) { updated in
                viewModel.updateReminder(updated)
            }
        }
        .navigationDestination(item: $selectedReminder) { reminder in
            ReminderDetailView(
                reminder: reminder,
                onUpdate: { viewModel.updateReminder($0) },
                onDelete: { viewModel.deleteReminder($0) },
                onToggleCompleted: { viewModel.toggleCompleted($0) }
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

    // MARK: - Filter

    private var filterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(
                    title: L("reminder.filter.all"),
                    isSelected: viewModel.selectedFilter == .all
                ) {
                    viewModel.selectedFilter = .all
                }

                FilterChip(
                    title: L("reminder.filter.pending"),
                    isSelected: viewModel.selectedFilter == .pending
                ) {
                    viewModel.selectedFilter = .pending
                }

                FilterChip(
                    title: L("reminder.filter.completed"),
                    isSelected: viewModel.selectedFilter == .completed
                ) {
                    viewModel.selectedFilter = .completed
                }

                FilterChip(
                    title: L("reminder.filter.overdue"),
                    isSelected: viewModel.selectedFilter == .overdue
                ) {
                    viewModel.selectedFilter = .overdue
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }

    // MARK: - Summary

    private var summaryBar: some View {
        HStack(spacing: 16) {
            Label(
                L("reminder.summary.pending", viewModel.pendingCount),
                systemImage: "circle"
            )
            .font(.caption)
            .foregroundColor(.secondary)

            if viewModel.overdueCount > 0 {
                Label(
                    L("reminder.summary.overdue", viewModel.overdueCount),
                    systemImage: "exclamationmark.triangle.fill"
                )
                .font(.caption)
                .foregroundColor(.red)
            }

            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(UIColor.systemBackground))
    }

    // MARK: - List

    private var listContent: some View {
        List {
            ForEach(viewModel.filteredReminders) { reminder in
                ReminderRowView(
                    reminder: reminder,
                    onToggle: { viewModel.toggleCompleted(reminder) }
                )
                .contentShape(Rectangle())
                .onTapGesture { selectedReminder = reminder }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        viewModel.deleteReminder(reminder)
                    } label: {
                        Label(L("button.delete"), systemImage: "trash")
                    }

                    Button {
                        viewModel.reminderToEdit = reminder
                    } label: {
                        Label(L("button.edit"), systemImage: "pencil")
                    }
                    .tint(.orange)
                }
            }
        }
        .listStyle(.plain)
    }

    // MARK: - Empty States

    private var emptyState: some View {
        TypedEmptyStateView(
            type: .reminders,
            actionTitle: L("reminder.list.add")
        ) {
            viewModel.showAddSheet = true
        }
    }

    private var filterEmptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "bell")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            Text(L("reminder.filter.no_results"))
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
