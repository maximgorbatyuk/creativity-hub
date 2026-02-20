import SwiftUI
import UniformTypeIdentifiers
import PhotosUI
import os

struct PendingDocument: Identifiable {
    let id = UUID()
    let tempURL: URL
    let fileName: String
    let fileSize: Int64
    let nameRequired: Bool
    let originalPath: String
}

struct DocumentPickerView: View {
    let projectId: UUID
    let onComplete: (Bool) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var showFilePicker = false
    @State private var showPhotoPicker = false
    @State private var showCamera = false
    @State private var selectedPhotoItems: [PhotosPickerItem] = []
    @State private var isProcessing = false
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var pendingDocuments: [PendingDocument] = []
    @State private var currentPendingIndex = 0
    @State private var showNameEntry = false
    @State private var entryName = ""

    private let analytics = AnalyticsService.shared

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        showFilePicker = true
                    } label: {
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(L("document.import.files"))
                                    .foregroundColor(.primary)
                                Text(L("document.import.files.description"))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        } icon: {
                            Image(systemName: "folder.fill")
                                .foregroundColor(.blue)
                        }
                    }

                    Button {
                        showPhotoPicker = true
                    } label: {
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(L("document.import.photos"))
                                    .foregroundColor(.primary)
                                Text(L("document.import.photos.description"))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        } icon: {
                            Image(systemName: "photo.fill")
                                .foregroundColor(.green)
                        }
                    }

                    Button {
                        showCamera = true
                    } label: {
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(L("document.import.camera"))
                                    .foregroundColor(.primary)
                                Text(L("document.import.camera.description"))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        } icon: {
                            Image(systemName: "camera.fill")
                                .foregroundColor(.orange)
                        }
                    }
                } header: {
                    Text(L("document.import.section.source"))
                } footer: {
                    Text(L("document.import.supported_formats"))
                }
            }
            .navigationTitle(L("document.import.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L("button.cancel")) { dismiss() }
                }
            }
            .overlay {
                if isProcessing {
                    ZStack {
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()

                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.2)
                            Text(L("document.import.processing"))
                                .font(.subheadline)
                                .foregroundColor(.white)
                        }
                        .padding(24)
                        .background(Color(UIColor.systemGray5))
                        .cornerRadius(12)
                    }
                }
            }
            .fileImporter(
                isPresented: $showFilePicker,
                allowedContentTypes: [.pdf, .jpeg, .png, .heic],
                allowsMultipleSelection: true
            ) { result in
                handleFileImport(result)
            }
            .photosPicker(
                isPresented: $showPhotoPicker,
                selection: $selectedPhotoItems,
                maxSelectionCount: 10,
                matching: .images
            )
            .onChange(of: selectedPhotoItems) { _, newItems in
                handlePhotoSelection(newItems)
            }
            .fullScreenCover(isPresented: $showCamera) {
                CameraView { image in
                    handleCapturedImage(image)
                }
            }
            .alert(L("error.generic.title"), isPresented: $showError) {
                Button(L("button.done"), role: .cancel) {}
            } message: {
                Text(errorMessage ?? "")
            }
            .alert(L("document.rename.title"), isPresented: $showNameEntry) {
                TextField(L("document.rename.placeholder"), text: $entryName)
                Button(L("button.cancel"), role: .cancel) {
                    saveCurrentPendingDocument(withName: nil)
                }
                Button(L("button.save")) {
                    let name = entryName.trimmingCharacters(in: .whitespacesAndNewlines)
                    saveCurrentPendingDocument(withName: name.isEmpty ? nil : name)
                }
            } message: {
                if currentPendingIndex < pendingDocuments.count {
                    Text(pendingDocuments[currentPendingIndex].fileName)
                }
            }
            .onAppear {
                analytics.trackScreen("document_picker")
            }
        }
    }

    // MARK: - File Import

    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            processFiles(urls)
        case .failure(let error):
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    private func processFiles(_ urls: [URL]) {
        guard !urls.isEmpty else { return }

        isProcessing = true

        Task {
            var pending: [PendingDocument] = []

            for url in urls {
                let accessing = url.startAccessingSecurityScopedResource()
                defer {
                    if accessing {
                        url.stopAccessingSecurityScopedResource()
                    }
                }

                if DocumentService.shared.isSupportedFileType(url) {
                    let fileName = url.lastPathComponent
                    let fileSize = (try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int64) ?? 0
                    let tempFileName = "\(UUID().uuidString)_\(fileName)"
                    let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(tempFileName)

                    do {
                        try FileManager.default.copyItem(at: url, to: tempURL)
                        pending.append(PendingDocument(
                            tempURL: tempURL,
                            fileName: fileName,
                            fileSize: fileSize,
                            nameRequired: false,
                            originalPath: url.path
                        ))
                    } catch {
                        logger.error("Failed to copy file to temp: \(error)")
                    }
                }
            }

            await MainActor.run {
                isProcessing = false

                if pending.isEmpty {
                    errorMessage = L("document.error.import_failed")
                    showError = true
                } else {
                    pendingDocuments = pending
                    currentPendingIndex = 0
                    entryName = ""
                    showNameEntry = true
                }
            }
        }
    }

    // MARK: - Photo Selection

    private func handlePhotoSelection(_ items: [PhotosPickerItem]) {
        guard !items.isEmpty else { return }

        isProcessing = true
        selectedPhotoItems = []

        Task {
            var pending: [PendingDocument] = []

            for item in items {
                if let data = try? await item.loadTransferable(type: Data.self) {
                    let fileName = "photo_\(UUID().uuidString).jpg"
                    let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

                    do {
                        try data.write(to: tempURL)
                        pending.append(PendingDocument(
                            tempURL: tempURL,
                            fileName: fileName,
                            fileSize: Int64(data.count),
                            nameRequired: true,
                            originalPath: ""
                        ))
                    } catch {
                        logger.error("Failed to process photo: \(error)")
                    }
                }
            }

            await MainActor.run {
                isProcessing = false

                if pending.isEmpty {
                    errorMessage = L("document.error.import_failed")
                    showError = true
                } else {
                    pendingDocuments = pending
                    currentPendingIndex = 0
                    entryName = ""
                    showNameEntry = true
                }
            }
        }
    }

    // MARK: - Camera

    private func handleCapturedImage(_ image: UIImage?) {
        guard let image, let data = image.jpegData(compressionQuality: 0.8) else { return }

        isProcessing = true

        Task {
            let fileName = "capture_\(UUID().uuidString).jpg"
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

            do {
                try data.write(to: tempURL)
                await MainActor.run {
                    isProcessing = false
                    pendingDocuments = [PendingDocument(
                        tempURL: tempURL,
                        fileName: fileName,
                        fileSize: Int64(data.count),
                        nameRequired: true,
                        originalPath: ""
                    )]
                    currentPendingIndex = 0
                    entryName = ""
                    showNameEntry = true
                }
            } catch {
                await MainActor.run {
                    isProcessing = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }

    // MARK: - Pending Document Handling

    private func saveCurrentPendingDocument(withName name: String?) {
        guard currentPendingIndex < pendingDocuments.count else { return }

        let pending = pendingDocuments[currentPendingIndex]
        let viewModel = DocumentsListViewModel(projectId: projectId)
        let filePath = pending.originalPath.isEmpty ? nil : pending.originalPath
        let wasSaved = viewModel.addDocument(from: pending.tempURL, name: name, filePath: filePath)

        try? FileManager.default.removeItem(at: pending.tempURL)

        guard wasSaved else {
            analytics.trackEvent("documents_import_failed", properties: ["index": currentPendingIndex])
            pendingDocuments = []
            currentPendingIndex = 0
            errorMessage = L("document.error.import_failed")
            showError = true
            onComplete(false)
            return
        }

        currentPendingIndex += 1

        if currentPendingIndex < pendingDocuments.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                entryName = ""
                showNameEntry = true
            }
        } else {
            analytics.trackEvent("documents_imported", properties: ["count": pendingDocuments.count])
            pendingDocuments = []
            onComplete(true)
            dismiss()
        }
    }

    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "-",
        category: "DocumentPickerView"
    )
}

// MARK: - Camera View

struct CameraView: UIViewControllerRepresentable {
    let onCapture: (UIImage?) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onCapture: onCapture)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onCapture: (UIImage?) -> Void

        init(onCapture: @escaping (UIImage?) -> Void) {
            self.onCapture = onCapture
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            let image = info[.originalImage] as? UIImage
            picker.dismiss(animated: true)
            onCapture(image)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
            onCapture(nil)
        }
    }
}
