import SwiftUI

struct iCloudBackupListView: View {
    @Bindable var viewModel: UserSettingsViewModel
    @Environment(\.dismiss) var dismiss

    @State private var backupToDelete: BackupInfo?
    @State private var showDeleteConfirmation = false
    @State private var backupToRestore: BackupInfo?
    @State private var showRestoreConfirmation = false
    @State private var showDeleteAllConfirmation = false

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoadingBackups {
                    ProgressView(L("backup.loading"))
                        .progressViewStyle(.circular)
                        .frame(maxHeight: .infinity)
                } else if viewModel.iCloudBackups.isEmpty {
                    emptyState
                } else {
                    backupList
                }
            }
            .navigationTitle(L("backup.icloud.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L("button.close")) {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Button {
                        Task {
                            await viewModel.loadiCloudBackups()
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(viewModel.isLoadingBackups)
                }
            }
            .alert(L("backup.delete.title"), isPresented: $showDeleteConfirmation) {
                Button(L("button.cancel"), role: .cancel) {
                    backupToDelete = nil
                }
                Button(L("button.delete"), role: .destructive) {
                    if let backup = backupToDelete {
                        Task {
                            await viewModel.deleteiCloudBackup(backup)
                            backupToDelete = nil
                        }
                    }
                }
            } message: {
                if let backup = backupToDelete {
                    Text(L("backup.delete.message") + " \(formatDate(backup.createdAt))")
                }
            }
            .alert(L("backup.restore.title"), isPresented: $showRestoreConfirmation) {
                Button(L("button.cancel"), role: .cancel) {
                    backupToRestore = nil
                }
                Button(L("backup.restore.action"), role: .destructive) {
                    if let backup = backupToRestore {
                        Task {
                            await viewModel.restoreFromiCloudBackup(backup)
                            backupToRestore = nil
                            dismiss()
                        }
                    }
                }
            } message: {
                Text(L("backup.restore.message"))
            }
            .alert(L("backup.delete_all.title"), isPresented: $showDeleteAllConfirmation) {
                Button(L("button.cancel"), role: .cancel) {}
                Button(L("backup.delete_all.action"), role: .destructive) {
                    Task {
                        await viewModel.deleteAlliCloudBackups()
                    }
                }
            } message: {
                Text(L("backup.delete_all.message"))
            }
            .alert(L("backup.error.title"), isPresented: isBackupErrorPresented) {
                Button(L("button.done")) {
                    viewModel.backupError = nil
                }
            } message: {
                if let error = viewModel.backupError {
                    Text(error)
                }
            }
        }
        .task {
            await viewModel.loadiCloudBackups()
        }
    }

    // MARK: - Empty State

    private var isBackupErrorPresented: Binding<Bool> {
        Binding(
            get: {
                viewModel.backupError != nil
            },
            set: { isPresented in
                if !isPresented {
                    viewModel.backupError = nil
                }
            }
        )
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "icloud.slash")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            Text(L("backup.icloud.empty.title"))
                .font(.title2)
                .foregroundColor(.secondary)

            Text(L("backup.icloud.empty.message"))
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxHeight: .infinity)
    }

    // MARK: - Backup List

    private var backupList: some View {
        List {
            ForEach(viewModel.iCloudBackups) { backup in
                BackupRow(backup: backup)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        backupToRestore = backup
                        showRestoreConfirmation = true
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            backupToDelete = backup
                            showDeleteConfirmation = true
                        } label: {
                            Label(L("button.delete"), systemImage: "trash")
                        }
                    }
            }

            if !viewModel.iCloudBackups.isEmpty {
                Section {
                    Button(role: .destructive) {
                        showDeleteAllConfirmation = true
                    } label: {
                        HStack {
                            Image(systemName: "trash.circle.fill")
                                .foregroundColor(.red)
                            Text(L("backup.delete_all.action"))
                                .foregroundColor(.red)
                        }
                    }
                }
            }
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Backup Row

struct BackupRow: View {
    let backup: BackupInfo

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "icloud.and.arrow.down")
                    .foregroundColor(.blue)

                Text(formatDate(backup.createdAt))
                    .font(.headline)

                Spacer()

                Text(backup.formattedFileSize)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Text(backup.deviceName)
                .font(.subheadline)
                .foregroundColor(.secondary)

            Text("v\(backup.appVersion)")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
