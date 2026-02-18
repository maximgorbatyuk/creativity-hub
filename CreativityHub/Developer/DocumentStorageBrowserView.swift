import SwiftUI

struct DocumentStorageBrowserView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var storageStats: StorageStats?
    @State private var folders: [StorageItem] = []
    @State private var rootFiles: [StorageItem] = []
    @State private var isLoading = true

    private let service = DocumentStorageService.shared

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        if let stats = storageStats {
                            StorageStatsSection(stats: stats)
                        }

                        if !folders.isEmpty {
                            Section(header: Text(L("developer.document_storage.folders"))) {
                                ForEach(folders) { folder in
                                    NavigationLink(destination: FolderContentsView(folder: folder)) {
                                        FolderRow(item: folder)
                                    }
                                }
                            }
                        }

                        if !rootFiles.isEmpty {
                            Section(header: Text(L("developer.document_storage.root_files"))) {
                                ForEach(rootFiles) { file in
                                    FileRow(item: file)
                                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                            Button(role: .destructive) {
                                                deleteFile(file)
                                            } label: {
                                                Label(L("button.delete"), systemImage: "trash")
                                            }
                                        }
                                }
                            }
                        }

                        if folders.isEmpty && rootFiles.isEmpty {
                            Section {
                                Text(L("developer.document_storage.no_files"))
                                    .foregroundColor(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .center)
                            }
                        }
                    }
                    .refreshable {
                        await loadData()
                    }
                }
            }
            .navigationTitle(L("developer.document_storage.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(L("button.done")) { dismiss() }
                }
            }
            .onAppear {
                Task {
                    await loadData()
                }
            }
        }
    }

    @MainActor
    private func loadData() async {
        isLoading = true

        await Task.yield()

        let result = await fetchStorageData()
        storageStats = result.stats
        folders = result.folders
        rootFiles = result.rootFiles
        isLoading = false
    }

    private func deleteFile(_ file: StorageItem) {
        Task {
            _ = await deleteItemAsync(at: file.url)
            await loadData()
        }
    }

    private func fetchStorageData() async -> (stats: StorageStats, folders: [StorageItem], rootFiles: [StorageItem]) {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let stats = service.getStorageStats()
                let items = service.getContents(of: service.rootDirectory)
                let folders = items.filter { $0.isDirectory }
                let rootFiles = items.filter { !$0.isDirectory }
                continuation.resume(returning: (stats: stats, folders: folders, rootFiles: rootFiles))
            }
        }
    }

    private func deleteItemAsync(at url: URL) async -> Bool {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                continuation.resume(returning: service.deleteItem(at: url))
            }
        }
    }
}
