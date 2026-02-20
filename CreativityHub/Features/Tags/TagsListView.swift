import SwiftUI

struct TagsListView: View {
    @State private var viewModel = TagsListViewModel()
    @State private var formMode: TagFormMode?

    private let analytics = AnalyticsService.shared

    var body: some View {
        Group {
            if viewModel.tags.isEmpty {
                ContentUnavailableView(
                    L("tags.empty"),
                    systemImage: "tag",
                    description: Text(L("tags.empty.message"))
                )
            } else {
                List {
                    ForEach(viewModel.tags) { tag in
                        TagRowView(tag: tag)
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    viewModel.confirmDelete(tag)
                                } label: {
                                    Label(L("button.delete"), systemImage: "trash")
                                }
                                Button {
                                    formMode = .edit(tag)
                                } label: {
                                    Label(L("button.edit"), systemImage: "pencil")
                                }
                                .tint(.orange)
                            }
                    }
                }
            }
        }
        .navigationTitle(L("tags.title"))
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    formMode = .add
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(item: $formMode) { mode in
            TagFormView(mode: mode) { tag in
                if case .edit = mode {
                    viewModel.updateTag(tag)
                } else {
                    viewModel.createTag(tag)
                }
            }
        }
        .alert(
            L("tags.delete.title"),
            isPresented: $viewModel.showDeleteConfirmation
        ) {
            Button(L("button.cancel"), role: .cancel) {
                viewModel.tagToDelete = nil
            }
            Button(L("button.delete"), role: .destructive) {
                viewModel.deleteTag()
            }
        } message: {
            Text(L("tags.delete.message"))
        }
        .onAppear {
            analytics.trackScreen("tags_list")
            viewModel.loadTags()
        }
        .refreshable {
            viewModel.loadTags()
        }
    }
}
