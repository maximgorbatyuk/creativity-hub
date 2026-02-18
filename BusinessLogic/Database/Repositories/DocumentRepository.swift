import Foundation
import SQLite
import os

class DocumentRepository {
    private let table = Table("documents")

    private let idColumn = Expression<String>("id")
    private let projectIdColumn = Expression<String>("project_id")
    private let nameColumn = Expression<String?>("name")
    private let fileTypeColumn = Expression<String>("file_type")
    private let fileNameColumn = Expression<String>("file_name")
    private let fileSizeColumn = Expression<Int64>("file_size")
    private let notesColumn = Expression<String?>("notes")
    private let createdAtColumn = Expression<Date>("created_at")

    private let db: Connection
    private let logger: Logger

    init(db: Connection, logger: Logger? = nil) {
        self.db = db
        self.logger = logger ?? Logger(
            subsystem: Bundle.main.bundleIdentifier ?? "-",
            category: "DocumentRepository"
        )
    }

    func fetchAll() -> [Document] {
        var documents: [Document] = []
        do {
            for row in try db.prepare(table.order(createdAtColumn.desc)) {
                if let document = mapRow(row) {
                    documents.append(document)
                }
            }
        } catch {
            logger.error("Failed to fetch all documents: \(error)")
        }
        return documents
    }

    func deleteAll() {
        do {
            try db.run(table.delete())
        } catch {
            logger.error("Failed to delete all documents: \(error)")
        }
    }

    func fetchByProjectId(projectId: UUID) -> [Document] {
        var documents: [Document] = []
        do {
            let query = table.filter(projectIdColumn == projectId.uuidString)
                .order(createdAtColumn.desc)
            for row in try db.prepare(query) {
                if let document = mapRow(row) {
                    documents.append(document)
                }
            }
        } catch {
            logger.error("Failed to fetch documents for project \(projectId): \(error)")
        }
        return documents
    }

    func fetchById(id: UUID) -> Document? {
        do {
            let query = table.filter(idColumn == id.uuidString)
            if let row = try db.pluck(query) {
                return mapRow(row)
            }
        } catch {
            logger.error("Failed to fetch document by id \(id): \(error)")
        }
        return nil
    }

    func insert(_ document: Document) -> Bool {
        do {
            try db.run(table.insert(
                idColumn <- document.id.uuidString,
                projectIdColumn <- document.projectId.uuidString,
                nameColumn <- document.name,
                fileTypeColumn <- document.fileType.rawValue,
                fileNameColumn <- document.fileName,
                fileSizeColumn <- document.fileSize,
                notesColumn <- document.notes,
                createdAtColumn <- document.createdAt
            ))
            logger.info("Inserted document: \(document.id)")
            return true
        } catch {
            logger.error("Failed to insert document: \(error)")
            return false
        }
    }

    func update(_ document: Document) -> Bool {
        let record = table.filter(idColumn == document.id.uuidString)
        do {
            try db.run(record.update(
                nameColumn <- document.name,
                fileTypeColumn <- document.fileType.rawValue,
                fileNameColumn <- document.fileName,
                fileSizeColumn <- document.fileSize,
                notesColumn <- document.notes
            ))
            logger.info("Updated document: \(document.id)")
            return true
        } catch {
            logger.error("Failed to update document: \(error)")
            return false
        }
    }

    func delete(id: UUID) -> Bool {
        let record = table.filter(idColumn == id.uuidString)
        do {
            try db.run(record.delete())
            logger.info("Deleted document: \(id)")
            return true
        } catch {
            logger.error("Failed to delete document: \(error)")
            return false
        }
    }

    func deleteByProjectId(projectId: UUID) -> Bool {
        let records = table.filter(projectIdColumn == projectId.uuidString)
        do {
            try db.run(records.delete())
            logger.info("Deleted documents for project: \(projectId)")
            return true
        } catch {
            logger.error("Failed to delete documents for project: \(error)")
            return false
        }
    }

    func countByProjectId(projectId: UUID) -> Int {
        do {
            return try db.scalar(table.filter(projectIdColumn == projectId.uuidString).count)
        } catch {
            logger.error("Failed to count documents: \(error)")
            return 0
        }
    }

    func search(query searchQuery: String) -> [Document] {
        var documents: [Document] = []
        let pattern = "%\(searchQuery)%"
        do {
            let query = table.filter(
                fileNameColumn.like(pattern) || nameColumn.like(pattern) || notesColumn.like(pattern)
            ).order(createdAtColumn.desc)
            for row in try db.prepare(query) {
                if let document = mapRow(row) {
                    documents.append(document)
                }
            }
        } catch {
            logger.error("Failed to search documents: \(error)")
        }
        return documents
    }

    // MARK: - Row Mapping

    private func mapRow(_ row: Row) -> Document? {
        guard let id = UUID(uuidString: row[idColumn]),
              let projectId = UUID(uuidString: row[projectIdColumn])
        else { return nil }

        let fileType = DocumentType(rawValue: row[fileTypeColumn]) ?? .other

        return Document(
            id: id,
            projectId: projectId,
            name: row[nameColumn],
            fileType: fileType,
            fileName: row[fileNameColumn],
            fileSize: row[fileSizeColumn],
            notes: row[notesColumn],
            createdAt: row[createdAtColumn]
        )
    }
}
