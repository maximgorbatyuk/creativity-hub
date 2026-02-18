import SwiftUI

struct DocumentsListView: View {
    @State private var viewModel: DocumentsListViewModel
    @State private var selectedDocument: Document?

    private let projectId: UUID
    private let analytics = AnalyticsService.shared

    init(projectId: UUID) {
        self.projectId = projectId
        _viewModel = State(initialValue: DocumentsListViewModel(projectId: projectId))
    }

    var body: some View {
        VStack(spacing: 0) {
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxHeight: .infinity)
            } else if viewModel.documents.isEmpty {
                emptyState
            } else {
                filterSection
                if !viewModel.documents.isEmpty {
                    summaryBar
                }
                if viewModel.filteredDocuments.isEmpty {
                    filterEmptyState
                } else {
                    listContent
                }
            }
        }
        .navigationTitle(L("document.list.title"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbarContent }
        .onAppear {
            viewModel.loadData()
            analytics.trackScreen("documents_list")
        }
        .refreshable { viewModel.loadData() }
        .sheet(isPresented: $viewModel.showImportSheet) {
            DocumentPickerView(projectId: projectId) { success in
                if success {
                    viewModel.loadData()
                }
            }
        }
        .sheet(item: $selectedDocument) { document in
            DocumentPreviewView(
                document: document,
                projectId: projectId,
                onDelete: { doc in
                    viewModel.deleteDocument(doc)
                    selectedDocument = nil
                },
                onRename: { doc, name in
                    viewModel.renameDocument(doc, newName: name)
                }
            )
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Button {
                viewModel.showImportSheet = true
            } label: {
                Image(systemName: "plus")
            }
        }
    }

    // MARK: - Filter

    private var filterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(DocumentFilter.allCases, id: \.self) { filter in
                    FilterChip(
                        title: filter.displayName,
                        isSelected: viewModel.selectedFilter == filter
                    ) {
                        viewModel.selectedFilter = filter
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }

    // MARK: - Summary

    private var summaryBar: some View {
        HStack {
            Label(
                L("document.summary.files_count", viewModel.totalCount),
                systemImage: "doc.fill"
            )
            .font(.caption)
            .foregroundColor(.secondary)

            Spacer()

            Text(viewModel.formattedTotalSize)
                .font(.caption)
                .foregroundColor(.accentColor)
                .fontWeight(.medium)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(UIColor.systemBackground))
    }

    // MARK: - List

    private var listContent: some View {
        List {
            ForEach(viewModel.filteredDocuments) { document in
                DocumentRowView(document: document)
                    .contentShape(Rectangle())
                    .onTapGesture { selectedDocument = document }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            viewModel.deleteDocument(document)
                        } label: {
                            Label(L("button.delete"), systemImage: "trash")
                        }
                    }
            }
        }
        .listStyle(.plain)
    }

    // MARK: - Empty States

    private var emptyState: some View {
        TypedEmptyStateView(
            type: .documents,
            actionTitle: L("document.list.add")
        ) {
            viewModel.showImportSheet = true
        }
    }

    private var filterEmptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            Text(L("document.filter.no_results"))
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
