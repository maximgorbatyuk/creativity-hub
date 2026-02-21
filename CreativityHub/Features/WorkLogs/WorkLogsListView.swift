import SwiftUI

struct WorkLogsListView: View {
    @State private var viewModel: WorkLogsListViewModel

    private let projectId: UUID
    private let analytics = AnalyticsService.shared

    init(projectId: UUID) {
        self.projectId = projectId
        _viewModel = State(initialValue: WorkLogsListViewModel(projectId: projectId))
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(spacing: 0) {
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxHeight: .infinity)
                } else if viewModel.workLogs.isEmpty {
                    emptyState
                } else {
                    totalSummaryCard
                    listContent
                }
            }

            floatingAddButton
        }
        .navigationTitle(L("worklog.list.title"))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.loadData()
            analytics.trackScreen("work_logs_list")
        }
        .refreshable { viewModel.loadData() }
        .sheet(isPresented: $viewModel.showAddSheet) {
            WorkLogFormView(
                mode: .add(projectId: projectId),
                checklistItems: viewModel.checklistItems
            ) { workLog in
                viewModel.addWorkLog(workLog)
            }
        }
    }

    // MARK: - Summary

    private var totalSummaryCard: some View {
        VStack(spacing: 4) {
            Text(L("worklog.list.total"))
                .font(.caption)
                .foregroundColor(.secondary)
            Text(viewModel.formattedTotalDuration)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.indigo)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    // MARK: - List

    private var listContent: some View {
        List {
            ForEach(viewModel.workLogs) { workLog in
                WorkLogRowView(
                    workLog: workLog,
                    checklistItemName: viewModel.checklistItemName(for: workLog)
                )
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        viewModel.deleteWorkLog(workLog)
                    } label: {
                        Label(L("button.delete"), systemImage: "trash")
                    }
                }
            }
        }
        .listStyle(.plain)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        TypedEmptyStateView(
            type: .workLogs,
            actionTitle: L("worklog.list.add")
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
                .background(Color.indigo)
                .clipShape(Circle())
                .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 2)
        }
        .padding(.trailing, 20)
        .padding(.bottom, 20)
    }
}
