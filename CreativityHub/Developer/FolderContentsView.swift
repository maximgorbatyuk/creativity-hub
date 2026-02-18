import SwiftUI
import QuickLook

struct FolderContentsView: View {
    let folder: StorageItem

    @State private var files: [StorageItem] = []
    @State private var projectName: String?
    @State private var selectedFile: StorageItem?
    @State private var showDeleteConfirmation = false
    @State private var fileToDelete: StorageItem?
    @State private var isLoading = true

    private let service = DocumentStorageService.shared
    private let projectRepository = DatabaseManager.shared.projectRepository

    var body: some View {
        List {
            if UUID(uuidString: folder.name) != nil {
                if let name = projectName {
                    Section {
                        HStack {
                            Image(systemName: "folder.fill")
                                .foregroundColor(.blue)
                            Text("\(L("tab.projects")): \(name)")
                                .font(.subheadline)
                        }
                    }
                }
            }

            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .center)
            } else if files.isEmpty {
                Section {
                    Text(L("developer.document_storage.no_files"))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            } else {
                Section {
                    ForEach(files) { file in
                        FileRow(item: file)
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    fileToDelete = file
                                    showDeleteConfirmation = true
                                } label: {
                                    Label(L("button.delete"), systemImage: "trash")
                                }
                            }
                            .onTapGesture {
                                selectedFile = file
                            }
                    }
                }
            }
        }
        .navigationTitle(String(folder.name.prefix(12)) + (folder.name.count > 12 ? "..." : ""))
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedFile) { file in
            FileDetailView(file: file)
        }
        .alert(L("developer.document_storage.delete_confirm.title"), isPresented: $showDeleteConfirmation) {
            Button(L("button.cancel"), role: .cancel) {}
            Button(L("button.delete"), role: .destructive) {
                if let file = fileToDelete {
                    deleteFile(file)
                }
            }
        } message: {
            Text(L("developer.document_storage.delete_confirm.message"))
        }
        .onAppear {
            loadData()
            loadProjectName()
        }
    }

    private func loadData() {
        isLoading = true
        let items = service.getContents(of: folder.url)
        files = items.filter { !$0.isDirectory }
        isLoading = false
    }

    private func loadProjectName() {
        guard let projectId = UUID(uuidString: folder.name) else { return }
        let projects = projectRepository?.fetchAll()
        projectName = projects?.first { $0.id == projectId }?.name
    }

    private func deleteFile(_ file: StorageItem) {
        _ = service.deleteItem(at: file.url)
        files.removeAll { $0.id == file.id }
    }
}
