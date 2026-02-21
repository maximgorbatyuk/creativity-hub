import SwiftUI

struct ProjectContentView: View {
    @State private var viewModel = ProjectContentViewModel()
    @State private var showAddProjectSheet = false
    @State private var showChecklistsList = false
    @State private var showIdeasList = false
    @State private var showNotesList = false
    @State private var showDocumentsList = false
    @State private var showExpensesList = false
    @State private var showRemindersList = false
    @State private var showAddItemSelector = false
    @State private var showAddChecklistSheet = false
    @State private var showAddIdeaSheet = false
    @State private var showAddNoteSheet = false
    @State private var showAddExpenseSheet = false
    @State private var showAddReminderSheet = false
    @State private var showAddDocumentSheet = false
    @State private var showWorkLogsList = false
    @State private var showAddWorkLogSheet = false

    private let analytics = AnalyticsService.shared

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                VStack(spacing: 0) {
                    if viewModel.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if viewModel.allProjects.isEmpty {
                        emptyStateView
                    } else {
                        // Project selector at top
                        ProjectSelectorView(
                            projects: viewModel.allProjects,
                            selectedProjectId: viewModel.selectedProjectId,
                            onSelect: { id in
                                viewModel.selectProject(id: id)
                            },
                            onCreateNew: {
                                showAddProjectSheet = true
                            }
                        )
                        .padding(.horizontal)
                        .padding(.top, 8)

                        // Scrollable sections
                        ScrollView {
                            LazyVStack(spacing: 0) {
                                checklistsSection
                                workLogsSection
                                documentsSection
                                expensesSection
                                remindersSection
                                ideasSection
                                notesSection
                                Spacer()
                                    .frame(height: 100)
                            }
                        }
                    }
                }
                .background(Color(.systemGray6))

                if viewModel.selectedProjectId != nil {
                    floatingAddButton
                }
            }
            .navigationTitle(L("project.content.title"))
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                analytics.trackScreen("project_content")
                viewModel.loadInitialData()
            }
            .refreshable {
                viewModel.refreshData()
            }
            .sheet(isPresented: $showAddProjectSheet) {
                ProjectFormView(mode: .add) { project in
                    viewModel.addProject(project)
                }
            }
            .sheet(isPresented: $showAddItemSelector) {
                addItemSelectorSheet
            }
            .sheet(isPresented: $showAddChecklistSheet) {
                ChecklistFormView { name in
                    viewModel.addChecklist(name: name)
                }
            }
            .sheet(isPresented: $showAddIdeaSheet) {
                if let projectId = viewModel.selectedProjectId {
                    IdeaFormView(mode: .add(projectId: projectId)) { idea in
                        viewModel.addIdea(idea)
                    }
                }
            }
            .sheet(isPresented: $showAddNoteSheet) {
                if let projectId = viewModel.selectedProjectId {
                    NoteFormView(mode: .add(projectId: projectId)) { note in
                        viewModel.addNote(note)
                    }
                }
            }
            .sheet(isPresented: $showAddExpenseSheet) {
                if let projectId = viewModel.selectedProjectId {
                    ExpenseFormView(
                        mode: .add(projectId: projectId),
                        categories: viewModel.expenseCategories,
                        defaultCurrency: viewModel.defaultCurrency
                    ) { expense in
                        viewModel.addExpense(expense)
                    }
                }
            }
            .sheet(isPresented: $showAddReminderSheet) {
                if let projectId = viewModel.selectedProjectId {
                    ReminderFormView(mode: .add(projectId: projectId)) { reminder in
                        viewModel.addReminder(reminder)
                    }
                }
            }
            .sheet(isPresented: $showAddDocumentSheet) {
                if let projectId = viewModel.selectedProjectId {
                    DocumentPickerView(projectId: projectId) { _ in
                        viewModel.refreshData()
                    }
                }
            }
            .navigationDestination(isPresented: $showChecklistsList) {
                ChecklistsListView(projectId: viewModel.selectedProjectId ?? UUID())
            }
            .navigationDestination(isPresented: $showIdeasList) {
                IdeasListView(projectId: viewModel.selectedProjectId ?? UUID())
            }
            .navigationDestination(isPresented: $showNotesList) {
                NotesListView(projectId: viewModel.selectedProjectId ?? UUID())
            }
            .navigationDestination(isPresented: $showDocumentsList) {
                DocumentsListView(projectId: viewModel.selectedProjectId ?? UUID())
            }
            .navigationDestination(isPresented: $showExpensesList) {
                ExpensesListView(projectId: viewModel.selectedProjectId ?? UUID())
            }
            .navigationDestination(isPresented: $showRemindersList) {
                RemindersListView(projectId: viewModel.selectedProjectId ?? UUID())
            }
            .navigationDestination(isPresented: $showWorkLogsList) {
                WorkLogsListView(projectId: viewModel.selectedProjectId ?? UUID())
            }
            .sheet(isPresented: $showAddWorkLogSheet) {
                if let projectId = viewModel.selectedProjectId {
                    WorkLogFormView(
                        mode: .add(projectId: projectId),
                        checklistItems: viewModel.workLogChecklistItems
                    ) { workLog in
                        viewModel.addWorkLog(workLog)
                    }
                }
            }
        }
    }

    // MARK: - Sections

    private var checklistsSection: some View {
        sectionContainer(
            header: SectionHeaderView(
                title: L("project.section.checklists"),
                iconName: "checklist",
                iconColor: .blue,
                itemCount: viewModel.sectionCounts.checklists,
                onSeeAll: viewModel.selectedProjectId != nil ? {
                    showChecklistsList = true
                } : nil
            ),
            content: {
                if viewModel.previewChecklists.isEmpty {
                    Button {
                        showChecklistsList = true
                    } label: {
                        EmptySectionView(
                            message: L("empty.checklists.message"),
                            iconName: "checklist"
                        )
                    }
                    .buttonStyle(.plain)
                } else {
                    ForEach(viewModel.previewChecklists) { checklist in
                        ChecklistPreviewRow(
                            checklist: checklist,
                            progress: viewModel.checklistItemProgress[checklist.id] ?? (checked: 0, total: 0)
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            showChecklistsList = true
                        }
                        if checklist.id != viewModel.previewChecklists.last?.id {
                            Divider().padding(.leading, 56)
                        }
                    }
                }
            }
        )
    }

    private var ideasSection: some View {
        sectionContainer(
            header: SectionHeaderView(
                title: L("project.section.ideas"),
                iconName: "lightbulb.fill",
                iconColor: .yellow,
                itemCount: viewModel.sectionCounts.ideas,
                onSeeAll: viewModel.selectedProjectId != nil ? {
                    showIdeasList = true
                } : nil
            ),
            content: {
                if viewModel.previewIdeas.isEmpty {
                    Button {
                        showIdeasList = true
                    } label: {
                        EmptySectionView(
                            message: L("empty.ideas.message"),
                            iconName: "lightbulb"
                        )
                    }
                    .buttonStyle(.plain)
                } else {
                    ForEach(viewModel.previewIdeas) { idea in
                        IdeaPreviewRow(idea: idea)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                showIdeasList = true
                            }
                        if idea.id != viewModel.previewIdeas.last?.id {
                            Divider().padding(.leading, 56)
                        }
                    }
                }
            }
        )
    }

    private var notesSection: some View {
        sectionContainer(
            header: SectionHeaderView(
                title: L("project.section.notes"),
                iconName: "note.text",
                iconColor: .orange,
                itemCount: viewModel.sectionCounts.notes,
                onSeeAll: viewModel.selectedProjectId != nil ? {
                    showNotesList = true
                } : nil
            ),
            content: {
                if viewModel.previewNotes.isEmpty {
                    Button {
                        showNotesList = true
                    } label: {
                        EmptySectionView(
                            message: L("empty.notes.message"),
                            iconName: "note.text"
                        )
                    }
                    .buttonStyle(.plain)
                } else {
                    ForEach(viewModel.previewNotes) { note in
                        NotePreviewRow(note: note)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                showNotesList = true
                            }
                        if note.id != viewModel.previewNotes.last?.id {
                            Divider().padding(.leading, 56)
                        }
                    }
                }
            }
        )
    }

    private var documentsSection: some View {
        sectionContainer(
            header: SectionHeaderView(
                title: L("project.section.documents"),
                iconName: "doc.fill",
                iconColor: .purple,
                itemCount: viewModel.sectionCounts.documents,
                onSeeAll: viewModel.selectedProjectId != nil ? {
                    showDocumentsList = true
                } : nil
            ),
            content: {
                if viewModel.previewDocuments.isEmpty {
                    Button {
                        showDocumentsList = true
                    } label: {
                        EmptySectionView(
                            message: L("empty.documents.message"),
                            iconName: "doc"
                        )
                    }
                    .buttonStyle(.plain)
                } else {
                    ForEach(viewModel.previewDocuments) { document in
                        DocumentPreviewRow(document: document)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                showDocumentsList = true
                            }
                        if document.id != viewModel.previewDocuments.last?.id {
                            Divider().padding(.leading, 56)
                        }
                    }
                }
            }
        )
    }

    private var expensesSection: some View {
        sectionContainer(
            header: SectionHeaderView(
                title: L("project.section.expenses"),
                iconName: "creditcard.fill",
                iconColor: .green,
                itemCount: viewModel.sectionCounts.expenses,
                onSeeAll: viewModel.selectedProjectId != nil ? {
                    showExpensesList = true
                } : nil
            ),
            content: {
                if viewModel.previewExpenses.isEmpty {
                    Button {
                        showExpensesList = true
                    } label: {
                        EmptySectionView(
                            message: L("empty.expenses.message"),
                            iconName: "creditcard"
                        )
                    }
                    .buttonStyle(.plain)
                } else {
                    ForEach(viewModel.previewExpenses) { expense in
                        ExpensePreviewRow(expense: expense)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                showExpensesList = true
                            }
                        if expense.id != viewModel.previewExpenses.last?.id {
                            Divider().padding(.leading, 56)
                        }
                    }
                }
            }
        )
    }

    private var remindersSection: some View {
        sectionContainer(
            header: SectionHeaderView(
                title: L("project.section.reminders"),
                iconName: "bell.fill",
                iconColor: .blue,
                itemCount: viewModel.sectionCounts.reminders,
                onSeeAll: viewModel.selectedProjectId != nil ? {
                    showRemindersList = true
                } : nil
            ),
            content: {
                if viewModel.previewReminders.isEmpty {
                    EmptySectionView(
                        message: L("empty.reminders.message"),
                        iconName: "bell"
                    )
                } else {
                    ForEach(viewModel.previewReminders) { reminder in
                        ReminderPreviewRow(reminder: reminder)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                showRemindersList = true
                            }
                        if reminder.id != viewModel.previewReminders.last?.id {
                            Divider().padding(.leading, 56)
                        }
                    }
                }
            }
        )
    }

    private var workLogsSection: some View {
        sectionContainer(
            header: SectionHeaderView(
                title: L("project.section.work_logs"),
                iconName: "clock.fill",
                iconColor: .indigo,
                itemCount: viewModel.sectionCounts.workLogs,
                onSeeAll: viewModel.selectedProjectId != nil ? {
                    showWorkLogsList = true
                } : nil
            ),
            content: {
                if viewModel.previewWorkLogs.isEmpty {
                    EmptySectionView(
                        message: L("empty.worklogs.message"),
                        iconName: "clock"
                    )
                } else {
                    ForEach(viewModel.previewWorkLogs) { workLog in
                        WorkLogPreviewRow(workLog: workLog)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                showWorkLogsList = true
                            }
                        if workLog.id != viewModel.previewWorkLogs.last?.id {
                            Divider().padding(.leading, 56)
                        }
                    }
                }
            }
        )
    }

    // MARK: - Section Container

    private func sectionContainer<Content: View>(
        header: SectionHeaderView,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(spacing: 0) {
            header
            Divider()
            content()
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .padding(.horizontal)
        .padding(.top, 12)
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "folder")
                .font(.system(size: 60))
                .foregroundColor(.gray)

            Text(L("project.content.empty.title"))
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.gray)

            Text(L("project.content.empty.subtitle"))
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button {
                showAddProjectSheet = true
            } label: {
                HStack {
                    Image(systemName: "plus")
                    Text(L("project.content.empty.add_button"))
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.accentColor)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Add Item Selector

    private var addItemSelectorSheet: some View {
        NavigationStack {
            let columns = [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ]

            ScrollView {
                LazyVGrid(columns: columns, spacing: 20) {
                    addItemGridButton(
                        icon: "checklist",
                        color: .blue,
                        title: L("project.section.checklists")
                    ) {
                        showAddItemSelector = false
                        showAddChecklistSheet = true
                    }

                    addItemGridButton(
                        icon: "lightbulb.fill",
                        color: .yellow,
                        title: L("project.section.ideas")
                    ) {
                        showAddItemSelector = false
                        showAddIdeaSheet = true
                    }

                    addItemGridButton(
                        icon: "note.text",
                        color: .orange,
                        title: L("project.section.notes")
                    ) {
                        showAddItemSelector = false
                        showAddNoteSheet = true
                    }

                    addItemGridButton(
                        icon: "doc.fill",
                        color: .purple,
                        title: L("project.section.documents")
                    ) {
                        showAddItemSelector = false
                        showAddDocumentSheet = true
                    }

                    addItemGridButton(
                        icon: "creditcard.fill",
                        color: .green,
                        title: L("project.section.expenses")
                    ) {
                        showAddItemSelector = false
                        showAddExpenseSheet = true
                    }

                    addItemGridButton(
                        icon: "bell.fill",
                        color: .red,
                        title: L("project.section.reminders")
                    ) {
                        showAddItemSelector = false
                        showAddReminderSheet = true
                    }

                    addItemGridButton(
                        icon: "clock.fill",
                        color: .indigo,
                        title: L("project.add_new.work_log")
                    ) {
                        showAddItemSelector = false
                        showAddWorkLogSheet = true
                    }
                }
                .padding(24)
            }
            .navigationTitle(L("project.content.add_item"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L("button.cancel")) {
                        showAddItemSelector = false
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func addItemGridButton(
        icon: String,
        color: Color,
        title: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 28))
                    .foregroundColor(.white)
                    .frame(width: 56, height: 56)
                    .background(color)
                    .clipShape(Circle())

                Text(title)
                    .font(.caption)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }

    // MARK: - FAB

    private var floatingAddButton: some View {
        Button {
            showAddItemSelector = true
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
    ProjectContentView()
}
