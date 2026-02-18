import SwiftUI
import QuickLook

struct FileDetailView: View {
    let file: StorageItem
    var onDelete: (() -> Void)? = nil

    @Environment(\.dismiss) private var dismiss
    @State private var attributes: FileAttributes?
    @State private var quickLookURL: URL?
    @State private var showShareSheet = false
    @State private var showDeleteConfirmation = false
    @State private var showDeleteError = false

    private let service = DocumentStorageService.shared

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        Spacer()
                        VStack(spacing: 12) {
                            Image(systemName: file.icon)
                                .font(.system(size: 48))
                                .foregroundColor(file.iconColor)
                            Text(file.name)
                                .font(.headline)
                                .multilineTextAlignment(.center)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 16)
                }

                Section(header: Text(L("developer.document_storage.file_info"))) {
                    InfoRow(label: L("developer.document_storage.type"), value: attributes?.type ?? "Unknown")
                    InfoRow(label: L("developer.document_storage.size"), value: file.formattedSize)
                    if let created = attributes?.creationDate {
                        InfoRow(label: L("developer.document_storage.created"), value: formatDate(created))
                    }
                    if let modified = attributes?.modificationDate {
                        InfoRow(label: L("developer.document_storage.modified"), value: formatDate(modified))
                    }
                    InfoRow(label: L("developer.document_storage.path"), value: attributes?.path ?? file.url.path)
                }

                Section {
                    Button {
                        quickLookURL = file.url
                    } label: {
                        Label(L("developer.document_storage.quick_look"), systemImage: "eye")
                    }

                    Button {
                        showShareSheet = true
                    } label: {
                        Label(L("developer.document_storage.share"), systemImage: "square.and.arrow.up")
                    }

                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        Label(L("developer.document_storage.delete"), systemImage: "trash")
                    }
                }
            }
            .navigationTitle(file.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(L("button.done")) { dismiss() }
                }
            }
            .quickLookPreview($quickLookURL)
            .sheet(isPresented: $showShareSheet) {
                ShareSheet(activityItems: [file.url])
            }
            .alert(L("developer.document_storage.delete_confirm.title"), isPresented: $showDeleteConfirmation) {
                Button(L("button.cancel"), role: .cancel) {}
                Button(L("button.delete"), role: .destructive) {
                    deleteFile()
                }
            } message: {
                Text(L("developer.document_storage.delete_confirm.message"))
            }
            .alert(L("error.generic.title"), isPresented: $showDeleteError) {
                Button(L("button.done")) {}
            } message: {
                Text(L("error.generic.message"))
            }
            .onAppear {
                attributes = service.getFileAttributes(at: file.url)
            }
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func deleteFile() {
        let didDelete = service.deleteItem(at: file.url)

        if didDelete {
            onDelete?()
            dismiss()
        } else {
            showDeleteError = true
        }
    }
}
