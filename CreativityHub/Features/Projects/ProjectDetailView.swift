import SwiftUI
import Charts

struct ProjectDetailView: View {
    @State private var viewModel: ProjectDetailViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var showEditSheet = false
    @State private var showDeleteConfirmation = false
    @State private var showChecklistsList = false
    @State private var showIdeasList = false
    @State private var showNotesList = false
    @State private var showDocumentsList = false
    @State private var showExpensesList = false
    @State private var showRemindersList = false
    @State private var showWorkLogsList = false

    private let analytics = AnalyticsService.shared

    init(project: Project) {
        _viewModel = State(initialValue: ProjectDetailViewModel(project: project))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                headerCard
                if viewModel.project.hasDateRange {
                    datesCard
                }

                if viewModel.project.hasBudget {
                    budgetCard
                }

                if viewModel.checklistProgress.total > 0 {
                    progressCard
                }

                activityChartCard

                projectActionsSection
                sectionsOverview
            }
            .padding()
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationTitle(viewModel.project.name)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.loadData()
            analytics.trackScreen("project_detail")
        }
        .refreshable { viewModel.loadData() }
        .sheet(isPresented: $showEditSheet) {
            ProjectFormView(mode: .edit(viewModel.project)) { updated in
                viewModel.updateProject(updated)
            }
        }
        .alert(L("project.delete.title"), isPresented: $showDeleteConfirmation) {
            Button(L("button.cancel"), role: .cancel) {}
            Button(L("button.delete"), role: .destructive) {
                if viewModel.deleteProject() {
                    dismiss()
                }
            }
        } message: {
            Text(L("project.delete.message"))
        }
        .navigationDestination(isPresented: $showChecklistsList) {
            ChecklistsListView(projectId: viewModel.project.id)
        }
        .navigationDestination(isPresented: $showIdeasList) {
            IdeasListView(projectId: viewModel.project.id)
        }
        .navigationDestination(isPresented: $showNotesList) {
            NotesListView(projectId: viewModel.project.id)
        }
        .navigationDestination(isPresented: $showDocumentsList) {
            DocumentsListView(projectId: viewModel.project.id)
        }
        .navigationDestination(isPresented: $showExpensesList) {
            ExpensesListView(projectId: viewModel.project.id)
        }
        .navigationDestination(isPresented: $showRemindersList) {
            RemindersListView(projectId: viewModel.project.id)
        }
        .navigationDestination(isPresented: $showWorkLogsList) {
            WorkLogsListView(projectId: viewModel.project.id)
        }
    }

    // MARK: - Header

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(projectColor.opacity(0.15))
                        .frame(width: 56, height: 56)

                    Image(systemName: viewModel.project.status.icon)
                        .font(.title2)
                        .foregroundColor(projectColor)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        if viewModel.project.isPinned {
                            Image(systemName: "pin.fill")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                        Text(viewModel.project.name)
                            .font(.title2)
                            .fontWeight(.bold)
                            .lineLimit(2)
                    }

                    Label(viewModel.project.status.displayName, systemImage: viewModel.project.status.icon)
                        .font(.subheadline)
                        .foregroundColor(viewModel.project.status.color)
                }

                Spacer()
            }

            if let description = viewModel.project.projectDescription, !description.isEmpty {
                Text(description)
                    .font(.body)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .cardBackground()
    }

    // MARK: - Dates

    private var datesCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(L("project.detail.dates"), systemImage: "calendar")
                .font(.headline)

            HStack(spacing: 16) {
                if let start = viewModel.project.startDate {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(L("project.detail.start"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(start, style: .date)
                            .font(.subheadline)
                    }
                }

                if let target = viewModel.project.targetDate {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(L("project.detail.target"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(target, style: .date)
                            .font(.subheadline)
                    }
                }

                Spacer()
            }
        }
        .padding()
        .cardBackground()
    }

    // MARK: - Progress

    private var progressCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label(L("project.detail.progress"), systemImage: "chart.bar.fill")
                    .font(.headline)

                Spacer()

                Text("\(viewModel.checklistProgress.checked)/\(viewModel.checklistProgress.total)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            ProgressView(value: viewModel.progressPercentage)
                .tint(viewModel.progressPercentage == 1.0 ? .green : .accentColor)

            Text(L("project.detail.progress_percent", Int(viewModel.progressPercentage * 100)))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .cardBackground()
    }

    // MARK: - Sections Overview

    private var activityChartCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L("project.activity_chart.title"))
                .font(.headline)

            Text(L("project.activity_chart.period"))
                .font(.caption)
                .foregroundColor(.secondary)

            Chart(viewModel.biweeklyActivityPoints) { point in
                LineMark(
                    x: .value("Period", point.date),
                    y: .value("Activities", point.count)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(projectColor)

                AreaMark(
                    x: .value("Period", point.date),
                    y: .value("Activities", point.count)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(projectColor.opacity(0.12))
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .month)) { _ in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel(format: .dateTime.month(.abbreviated))
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .frame(height: 200)
        }
        .padding()
        .cardBackground()
    }

    private var sectionsOverview: some View {
        VStack(spacing: 0) {
            sectionRow(
                icon: "checklist",
                color: .blue,
                title: L("project.section.checklists"),
                count: viewModel.sectionCounts.checklists
            ) {
                showChecklistsList = true
            }
            Divider().padding(.leading, 52)
            sectionRow(
                icon: "lightbulb.fill",
                color: .yellow,
                title: L("project.section.ideas"),
                count: viewModel.sectionCounts.ideas
            ) {
                showIdeasList = true
            }
            Divider().padding(.leading, 52)
            sectionRow(
                icon: "note.text",
                color: .orange,
                title: L("project.section.notes"),
                count: viewModel.sectionCounts.notes
            ) {
                showNotesList = true
            }
            Divider().padding(.leading, 52)
            sectionRow(
                icon: "doc.fill",
                color: .purple,
                title: L("project.section.documents"),
                count: viewModel.sectionCounts.documents
            ) {
                showDocumentsList = true
            }
            Divider().padding(.leading, 52)
            sectionRow(
                icon: "creditcard.fill",
                color: .green,
                title: L("project.section.expenses"),
                count: viewModel.sectionCounts.expenses
            ) {
                showExpensesList = true
            }
            Divider().padding(.leading, 52)
            sectionRow(
                icon: "bell.fill",
                color: .blue,
                title: L("project.section.reminders"),
                count: viewModel.sectionCounts.reminders
            ) {
                showRemindersList = true
            }
            Divider().padding(.leading, 52)
            sectionRow(
                icon: "clock.fill",
                color: .indigo,
                title: L("project.section.work_logs"),
                count: viewModel.sectionCounts.workLogs
            ) {
                showWorkLogsList = true
            }
        }
        .cardBackground()
    }

    private func sectionRow(
        icon: String,
        color: Color,
        title: String,
        count: Int,
        action: (() -> Void)? = nil
    ) -> some View {
        Button {
            action?()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                    .frame(width: 32)

                Text(title)
                    .font(.body)
                    .foregroundColor(.primary)

                Spacer()

                Text("\(count)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
        }
        .buttonStyle(.plain)
    }

    // MARK: - Budget

    private var budgetCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(L("project.detail.budget"), systemImage: "banknote.fill")
                .font(.headline)

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(L("project.detail.budget_total"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(viewModel.project.formattedBudget ?? "")
                        .font(.title3)
                        .fontWeight(.semibold)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(L("project.detail.spent"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(spentFormatted)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(isOverBudget ? .red : .primary)
                }
            }

            if let budget = viewModel.project.budget, budget > 0 {
                ProgressView(value: min(budgetUsage, 1.0))
                    .tint(isOverBudget ? .red : .green)
            }
        }
        .padding()
        .cardBackground()
    }

    // MARK: - Actions

    private var projectActionsSection: some View {
        HStack(spacing: 8) {
            actionButton(
                title: L("button.edit"),
                systemImage: "pencil",
                tintColor: .blue
            ) {
                showEditSheet = true
            }

            actionButton(
                title: viewModel.project.isPinned ? L("project.action.unpin") : L("project.action.pin"),
                systemImage: viewModel.project.isPinned ? "pin.slash" : "pin",
                tintColor: .orange
            ) {
                viewModel.togglePin()
            }

            Menu {
                ForEach(ProjectStatus.allCases) { status in
                    Button {
                        viewModel.updateStatus(status)
                    } label: {
                        Label(status.displayName, systemImage: status.icon)
                    }
                    .disabled(viewModel.project.status == status)
                }
            } label: {
                actionLabel(
                    title: L("project.action.set_status"),
                    systemImage: "flag.fill",
                    tintColor: .indigo
                )
            }

            actionButton(
                title: L("button.delete"),
                systemImage: "trash",
                tintColor: .red
            ) {
                showDeleteConfirmation = true
            }
        }
    }

    private func actionButton(
        title: String,
        systemImage: String,
        tintColor: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            actionLabel(title: title, systemImage: systemImage, tintColor: tintColor)
        }
        .buttonStyle(.plain)
    }

    private func actionLabel(
        title: String,
        systemImage: String,
        tintColor: Color
    ) -> some View {
        VStack(spacing: 6) {
            Image(systemName: systemImage)
                .font(.system(size: 20))
            Text(title)
                .font(.caption2)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .fontWeight(.semibold)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .foregroundColor(tintColor)
        .background(tintColor.opacity(0.1))
        .cornerRadius(12)
    }

    // MARK: - Helpers

    private var projectColor: Color {
        if let colorName = viewModel.project.coverColor {
            return Color.fromProjectColor(colorName)
        }
        return viewModel.project.status.color
    }

    private var spentFormatted: String {
        let currency = viewModel.project.budgetCurrency ?? .usd
        return currency.format(viewModel.totalExpenses)
    }

    private var budgetUsage: Double {
        guard let budget = viewModel.project.budget, budget > 0 else { return 0 }
        return NSDecimalNumber(decimal: viewModel.totalExpenses / budget).doubleValue
    }

    private var isOverBudget: Bool {
        guard let budget = viewModel.project.budget else { return false }
        return viewModel.totalExpenses > budget
    }
}
