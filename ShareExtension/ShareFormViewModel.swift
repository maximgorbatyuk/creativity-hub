import Combine
import Foundation
import os

/// ViewModel managing the Share Extension form state and validation.
@MainActor
final class ShareFormViewModel: ObservableObject {

    // MARK: - Form State

    @Published var selectedProjectId: UUID?
    @Published var selectedType: ShareObjectType?
    @Published var name: String = ""
    @Published var noteText: String = ""
    @Published var noteDescription: String = ""

    // MARK: - Data

    @Published var projects: [Project] = []
    @Published var sharedInput: SharedInput?

    // MARK: - UI State

    @Published var isSaving = false
    @Published var errorMessage: String?

    // MARK: - Callbacks

    var onComplete: (() -> Void)?
    var onCancel: (() -> Void)?

    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "-",
        category: "ShareFormViewModel"
    )

    // MARK: - Validation

    var isProjectSelected: Bool {
        selectedProjectId != nil
    }

    var isTypeSelected: Bool {
        selectedType != nil
    }

    var isNameValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var isNoteTextValid: Bool {
        !noteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// Returns true when all required fields are filled for the selected type.
    var isFormValid: Bool {
        guard isProjectSelected, let selectedType else {
            return false
        }

        switch selectedType {
        case .idea, .document:
            return isNameValid
        case .note:
            return isNoteTextValid
        }
    }

    var canSave: Bool {
        isFormValid && !isSaving
    }

    var hasProjects: Bool {
        !projects.isEmpty
    }

    // MARK: - Initialization

    func configure(input: SharedInput, projects: [Project]) {
        self.sharedInput = input
        self.projects = projects

        // Auto-select first project if only one exists
        if projects.count == 1 {
            selectedProjectId = projects.first?.id
        }

        // Pre-fill fields based on input kind
        prefillFromInput(input)
    }

    private func prefillFromInput(_ input: SharedInput) {
        switch input.kind {
        case .link:
            selectedType = .idea
            name = input.suggestedTitle ?? ""
        case .text:
            selectedType = .note
            noteText = input.text ?? ""
            name = input.suggestedTitle ?? ""
        case .image:
            selectedType = .idea
            name = input.suggestedTitle ?? ""
        }
    }

    // MARK: - Actions

    func save() {
        guard canSave, let projectId = selectedProjectId, let type = selectedType else {
            return
        }

        isSaving = true
        errorMessage = nil

        let success: Bool

        switch type {
        case .idea:
            success = saveIdea(projectId: projectId)
        case .document:
            success = saveDocument(projectId: projectId)
        case .note:
            success = saveNote(projectId: projectId)
        }

        isSaving = false

        if success {
            logger.info("Saved \(type.rawValue) to project \(projectId)")
            cleanupTempFiles()
            onComplete?()
        } else {
            errorMessage = L("share.error.save_failed")
            logger.error("Failed to save \(type.rawValue) to project \(projectId)")
        }
    }

    func cancel() {
        cleanupTempFiles()
        onCancel?()
    }

    // MARK: - Persistence

    private func saveIdea(projectId: UUID) -> Bool {
        guard let repo = DatabaseManager.shared.ideaRepository else { return false }
        guard let input = sharedInput else { return false }

        let persistedImageURL = persistedImageURLIfNeeded(from: input)
        if input.kind == .image, persistedImageURL == nil {
            return false
        }

        let url: String? = input.url?.absoluteString
        let sourceType: IdeaSourceType = {
            if let urlString = url {
                return IdeaSourceType.detect(from: urlString)
            }
            return .other
        }()

        let idea = Idea(
            projectId: projectId,
            url: url,
            title: name.trimmingCharacters(in: .whitespacesAndNewlines),
            thumbnailUrl: persistedImageURL?.absoluteString,
            sourceDomain: input.url?.host,
            sourceType: sourceType,
            notes: input.suggestedSnippet ?? input.originalFilename
        )

        let inserted = repo.insert(idea)
        if !inserted, let persistedImageURL {
            try? FileManager.default.removeItem(at: persistedImageURL)
        }

        return inserted
    }

    private func saveDocument(projectId: UUID) -> Bool {
        guard let repo = DatabaseManager.shared.documentRepository else { return false }
        guard let input = sharedInput else { return false }

        let documentService = DocumentService.shared
        let persistedImageURL = persistedImageURLIfNeeded(from: input)
        if input.kind == .image, persistedImageURL == nil {
            return false
        }

        let data: Data
        let sourceFileName: String
        let fileType: DocumentType
        let notes: String?

        switch input.kind {
        case .link:
            guard let urlString = input.url?.absoluteString,
                  let payload = urlString.data(using: .utf8)
            else {
                return false
            }

            data = payload
            sourceFileName = input.originalFilename ?? "shared_link.txt"
            fileType = .other
            notes = input.suggestedSnippet

        case .text:
            guard let text = input.text,
                  let payload = text.data(using: .utf8)
            else {
                return false
            }

            data = payload
            sourceFileName = input.originalFilename ?? "shared_text.txt"
            fileType = .other
            notes = input.suggestedSnippet

        case .image:
            guard let persistedImageURL else {
                return false
            }

            do {
                data = try Data(contentsOf: persistedImageURL)
            } catch {
                logger.error("Failed to read persisted image: \(error.localizedDescription)")
                return false
            }

            sourceFileName = input.originalFilename ?? persistedImageURL.lastPathComponent
            fileType = DocumentType.fromExtension(URL(fileURLWithPath: sourceFileName).pathExtension)
            notes = input.suggestedSnippet
        }

        guard let fileURL = documentService.saveDocument(data: data, fileName: sourceFileName, projectId: projectId) else {
            if let persistedImageURL {
                try? FileManager.default.removeItem(at: persistedImageURL)
            }
            return false
        }

        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let document = Document(
            projectId: projectId,
            name: trimmedName.isEmpty ? nil : trimmedName,
            fileType: fileType,
            fileName: fileURL.lastPathComponent,
            fileSize: Int64(data.count),
            notes: notes
        )

        let inserted = repo.insert(document)

        if !inserted, let persistedImageURL {
            try? FileManager.default.removeItem(at: persistedImageURL)
        }

        if !inserted {
            _ = documentService.deleteDocument(fileName: fileURL.lastPathComponent, projectId: projectId)
        }

        return inserted
    }

    private func saveNote(projectId: UUID) -> Bool {
        guard let repo = DatabaseManager.shared.noteRepository else { return false }

        let trimmedText = noteText.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDescription = noteDescription.trimmingCharacters(in: .whitespacesAndNewlines)

        let persistedImageURL = persistedImageURLIfNeeded(from: sharedInput)
        if sharedInput?.kind == .image, persistedImageURL == nil {
            return false
        }

        let title = trimmedText.components(separatedBy: .newlines)
            .first?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        var contentParts: [String] = [trimmedText]

        if !trimmedDescription.isEmpty {
            contentParts.append(trimmedDescription)
        }

        if let persistedImageURL {
            contentParts.append(persistedImageURL.absoluteString)
        }

        let content = contentParts
            .filter { !$0.isEmpty }
            .joined(separator: "\n\n")

        let note = Note(
            projectId: projectId,
            title: title.isEmpty ? L("share.type.note") : String(title.prefix(100)),
            content: content
        )

        let inserted = repo.insert(note)
        if !inserted, let persistedImageURL {
            try? FileManager.default.removeItem(at: persistedImageURL)
        }

        return inserted
    }

    private func persistedImageURLIfNeeded(from input: SharedInput?) -> URL? {
        guard
            let input,
            input.kind == .image,
            let tempImageURL = input.imageFileURL
        else {
            return nil
        }

        let filename = input.originalFilename ?? tempImageURL.lastPathComponent
        let destinationURL = AppGroupContainer.documentsURL
            .appendingPathComponent("shared_\(UUID().uuidString)_\(filename)")

        do {
            try FileManager.default.copyItem(at: tempImageURL, to: destinationURL)
            return destinationURL
        } catch {
            logger.error("Failed to persist shared image: \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - Cleanup

    private func cleanupTempFiles() {
        if let imageURL = sharedInput?.imageFileURL {
            try? FileManager.default.removeItem(at: imageURL)
        }
    }
}
