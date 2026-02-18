import Foundation
import os

class DocumentService {

    static let shared = DocumentService()

    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "-",
        category: "DocumentService"
    )
    private let fileManager = FileManager.default

    private init() {}

    // MARK: - Directory Management

    func getDocumentsDirectory() -> URL {
        AppGroupContainer.documentsURL
    }

    func getProjectDocumentsDirectory(projectId: UUID) -> URL {
        let directory = getDocumentsDirectory()
            .appendingPathComponent(projectId.uuidString, isDirectory: true)

        if !fileManager.fileExists(atPath: directory.path) {
            do {
                try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
                logger.info("Created directory for project: \(projectId)")
            } catch {
                logger.error("Failed to create project directory: \(error)")
            }
        }

        return directory
    }

    // MARK: - File Operations

    func saveDocument(from sourceURL: URL, projectId: UUID) -> (url: URL, fileName: String, fileSize: Int64)? {
        let directory = getProjectDocumentsDirectory(projectId: projectId)
        let originalFileName = sourceURL.lastPathComponent
        let uniqueFileName = generateUniqueFileName(originalFileName, in: directory)
        let destinationURL = directory.appendingPathComponent(uniqueFileName)

        do {
            let didStartAccessing = sourceURL.startAccessingSecurityScopedResource()
            defer {
                if didStartAccessing {
                    sourceURL.stopAccessingSecurityScopedResource()
                }
            }

            try fileManager.copyItem(at: sourceURL, to: destinationURL)

            let attributes = try fileManager.attributesOfItem(atPath: destinationURL.path)
            let fileSize = (attributes[.size] as? Int64) ?? 0

            logger.info("Copied document: \(uniqueFileName) for project: \(projectId)")
            return (destinationURL, uniqueFileName, fileSize)
        } catch {
            logger.error("Failed to copy document: \(error)")
            return nil
        }
    }

    func saveDocument(data: Data, fileName: String, projectId: UUID) -> URL? {
        let directory = getProjectDocumentsDirectory(projectId: projectId)
        let uniqueFileName = generateUniqueFileName(fileName, in: directory)
        let fileURL = directory.appendingPathComponent(uniqueFileName)

        do {
            try data.write(to: fileURL)
            logger.info("Saved document: \(uniqueFileName) for project: \(projectId)")
            return fileURL
        } catch {
            logger.error("Failed to save document: \(error)")
            return nil
        }
    }

    func getDocumentURL(fileName: String, projectId: UUID) -> URL {
        getProjectDocumentsDirectory(projectId: projectId).appendingPathComponent(fileName)
    }

    func documentExists(fileName: String, projectId: UUID) -> Bool {
        let fileURL = getDocumentURL(fileName: fileName, projectId: projectId)
        return fileManager.fileExists(atPath: fileURL.path)
    }

    func deleteDocument(fileName: String, projectId: UUID) -> Bool {
        let fileURL = getDocumentURL(fileName: fileName, projectId: projectId)

        guard fileManager.fileExists(atPath: fileURL.path) else {
            logger.warning("Document not found for deletion: \(fileName)")
            return true
        }

        do {
            try fileManager.removeItem(at: fileURL)
            logger.info("Deleted document: \(fileName)")
            return true
        } catch {
            logger.error("Failed to delete document: \(error)")
            return false
        }
    }

    func deleteAllDocuments(projectId: UUID) -> Bool {
        let directory = getProjectDocumentsDirectory(projectId: projectId)

        do {
            if fileManager.fileExists(atPath: directory.path) {
                try fileManager.removeItem(at: directory)
                logger.info("Deleted all documents for project: \(projectId)")
            }
            return true
        } catch {
            logger.error("Failed to delete documents for project: \(error)")
            return false
        }
    }

    // MARK: - File Info

    func getDocumentType(from url: URL) -> DocumentType {
        DocumentType.fromExtension(url.pathExtension)
    }

    func isSupportedFileType(_ url: URL) -> Bool {
        let supportedExtensions = ["pdf", "jpg", "jpeg", "png", "heic"]
        return supportedExtensions.contains(url.pathExtension.lowercased())
    }

    func formattedFileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }

    // MARK: - Helpers

    private func generateUniqueFileName(_ originalName: String, in directory: URL) -> String {
        let fileURL = directory.appendingPathComponent(originalName)

        if !fileManager.fileExists(atPath: fileURL.path) {
            return originalName
        }

        let nameWithoutExtension = (originalName as NSString).deletingPathExtension
        let fileExtension = (originalName as NSString).pathExtension

        var counter = 1
        var newName: String

        repeat {
            if fileExtension.isEmpty {
                newName = "\(nameWithoutExtension)_\(counter)"
            } else {
                newName = "\(nameWithoutExtension)_\(counter).\(fileExtension)"
            }
            counter += 1
        } while fileManager.fileExists(atPath: directory.appendingPathComponent(newName).path)

        return newName
    }
}
