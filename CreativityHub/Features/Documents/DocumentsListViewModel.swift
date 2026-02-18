import Foundation
import os

enum DocumentFilter: String, CaseIterable {
    case all
    case pdf
    case images

    var displayName: String {
        switch self {
        case .all: return L("document.filter.all")
        case .pdf: return L("document.filter.pdf")
        case .images: return L("document.filter.images")
        }
    }
}

@MainActor
@Observable
final class DocumentsListViewModel {

    // MARK: - State

    var documents: [Document] = []
    var filteredDocuments: [Document] = []
    var selectedFilter: DocumentFilter = .all {
        didSet { applyFilter() }
    }
    var isLoading = false

    var showImportSheet = false

    let projectId: UUID

    // MARK: - Private

    private let documentRepository: DocumentRepository?
    private let projectRepository: ProjectRepository?
    private let documentService = DocumentService.shared
    private let logger: Logger

    // MARK: - Init

    init(projectId: UUID, databaseManager: DatabaseManager = .shared) {
        self.projectId = projectId
        self.documentRepository = databaseManager.documentRepository
        self.projectRepository = databaseManager.projectRepository
        self.logger = Logger(
            subsystem: Bundle.main.bundleIdentifier ?? "-",
            category: "DocumentsListViewModel"
        )
    }

    // MARK: - Public

    func loadData() {
        isLoading = true
        documents = documentRepository?.fetchByProjectId(projectId: projectId) ?? []
        applyFilter()
        isLoading = false
    }

    func addDocument(from url: URL, name: String? = nil) -> Bool {
        guard let result = documentService.saveDocument(from: url, projectId: projectId) else {
            logger.error("Failed to save document file from URL")
            return false
        }

        let documentType = documentService.getDocumentType(from: url)
        let documentName: String? = (name?.isEmpty == false) ? name : nil

        let document = Document(
            projectId: projectId,
            name: documentName,
            fileType: documentType,
            fileName: result.fileName,
            fileSize: result.fileSize
        )

        if documentRepository?.insert(document) == true {
            projectRepository?.touchUpdatedAt(id: projectId)
            logger.info("Added document \(document.id)")
            loadData()
            return true
        } else {
            _ = documentService.deleteDocument(fileName: result.fileName, projectId: projectId)
            logger.error("Failed to insert document into database")
            return false
        }
    }

    func addDocumentFromData(_ data: Data, fileName: String, name: String? = nil) -> Bool {
        guard let fileURL = documentService.saveDocument(data: data, fileName: fileName, projectId: projectId) else {
            logger.error("Failed to save document data")
            return false
        }

        let savedFileName = fileURL.lastPathComponent
        let documentType = DocumentType.fromExtension(fileURL.pathExtension)
        let documentName: String? = (name?.isEmpty == false) ? name : nil
        let fileSize = Int64(data.count)

        let document = Document(
            projectId: projectId,
            name: documentName,
            fileType: documentType,
            fileName: savedFileName,
            fileSize: fileSize
        )

        if documentRepository?.insert(document) == true {
            projectRepository?.touchUpdatedAt(id: projectId)
            logger.info("Added document \(document.id)")
            loadData()
            return true
        } else {
            _ = documentService.deleteDocument(fileName: savedFileName, projectId: projectId)
            logger.error("Failed to insert document into database")
            return false
        }
    }

    func deleteDocument(_ document: Document) {
        _ = documentService.deleteDocument(fileName: document.fileName, projectId: projectId)

        guard documentRepository?.delete(id: document.id) == true else {
            logger.error("Failed to delete document \(document.id)")
            return
        }
        projectRepository?.touchUpdatedAt(id: projectId)
        logger.info("Deleted document \(document.id)")
        loadData()
    }

    func renameDocument(_ document: Document, newName: String?) {
        var updated = document
        updated.name = newName

        guard documentRepository?.update(updated) == true else {
            logger.error("Failed to rename document \(document.id)")
            return
        }
        projectRepository?.touchUpdatedAt(id: projectId)
        logger.info("Renamed document \(document.id)")
        loadData()
    }

    func getDocumentURL(_ document: Document) -> URL {
        documentService.getDocumentURL(fileName: document.fileName, projectId: projectId)
    }

    func documentExists(_ document: Document) -> Bool {
        documentService.documentExists(fileName: document.fileName, projectId: projectId)
    }

    // MARK: - Statistics

    var totalCount: Int { documents.count }

    var totalFileSize: Int64 {
        documents.reduce(0) { $0 + $1.fileSize }
    }

    var formattedTotalSize: String {
        documentService.formattedFileSize(totalFileSize)
    }

    // MARK: - Private

    private func applyFilter() {
        switch selectedFilter {
        case .all:
            filteredDocuments = documents
        case .pdf:
            filteredDocuments = documents.filter(\.isPDF)
        case .images:
            filteredDocuments = documents.filter(\.isImage)
        }
    }
}
