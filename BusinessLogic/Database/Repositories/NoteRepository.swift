import Foundation
import SQLite
import os

class NoteRepository {
    private let table = Table("notes")

    private let idColumn = Expression<String>("id")
    private let projectIdColumn = Expression<String>("project_id")
    private let titleColumn = Expression<String>("title")
    private let contentColumn = Expression<String>("content")
    private let isPinnedColumn = Expression<Bool>("is_pinned")
    private let sortOrderColumn = Expression<Int>("sort_order")
    private let createdAtColumn = Expression<Date>("created_at")
    private let updatedAtColumn = Expression<Date>("updated_at")

    private let db: Connection
    private let logger: Logger

    init(db: Connection, logger: Logger? = nil) {
        self.db = db
        self.logger = logger ?? Logger(
            subsystem: Bundle.main.bundleIdentifier ?? "-",
            category: "NoteRepository"
        )
    }

    func fetchByProjectId(projectId: UUID) -> [Note] {
        var notes: [Note] = []
        do {
            let query = table.filter(projectIdColumn == projectId.uuidString)
                .order(isPinnedColumn.desc, updatedAtColumn.desc)
            for row in try db.prepare(query) {
                if let note = mapRow(row) {
                    notes.append(note)
                }
            }
        } catch {
            logger.error("Failed to fetch notes for project \(projectId): \(error)")
        }
        return notes
    }

    func fetchById(id: UUID) -> Note? {
        do {
            let query = table.filter(idColumn == id.uuidString)
            if let row = try db.pluck(query) {
                return mapRow(row)
            }
        } catch {
            logger.error("Failed to fetch note by id \(id): \(error)")
        }
        return nil
    }

    func insert(_ note: Note) -> Bool {
        do {
            try db.run(table.insert(
                idColumn <- note.id.uuidString,
                projectIdColumn <- note.projectId.uuidString,
                titleColumn <- note.title,
                contentColumn <- note.content,
                isPinnedColumn <- note.isPinned,
                sortOrderColumn <- note.sortOrder,
                createdAtColumn <- note.createdAt,
                updatedAtColumn <- note.updatedAt
            ))
            logger.info("Inserted note: \(note.id)")
            return true
        } catch {
            logger.error("Failed to insert note: \(error)")
            return false
        }
    }

    func update(_ note: Note) -> Bool {
        let record = table.filter(idColumn == note.id.uuidString)
        do {
            try db.run(record.update(
                titleColumn <- note.title,
                contentColumn <- note.content,
                isPinnedColumn <- note.isPinned,
                sortOrderColumn <- note.sortOrder,
                updatedAtColumn <- Date()
            ))
            logger.info("Updated note: \(note.id)")
            return true
        } catch {
            logger.error("Failed to update note: \(error)")
            return false
        }
    }

    func delete(id: UUID) -> Bool {
        let record = table.filter(idColumn == id.uuidString)
        do {
            try db.run(record.delete())
            logger.info("Deleted note: \(id)")
            return true
        } catch {
            logger.error("Failed to delete note: \(error)")
            return false
        }
    }

    func deleteByProjectId(projectId: UUID) -> Bool {
        let records = table.filter(projectIdColumn == projectId.uuidString)
        do {
            try db.run(records.delete())
            logger.info("Deleted notes for project: \(projectId)")
            return true
        } catch {
            logger.error("Failed to delete notes for project: \(error)")
            return false
        }
    }

    func countByProjectId(projectId: UUID) -> Int {
        do {
            return try db.scalar(table.filter(projectIdColumn == projectId.uuidString).count)
        } catch {
            logger.error("Failed to count notes: \(error)")
            return 0
        }
    }

    func search(query searchQuery: String) -> [Note] {
        var notes: [Note] = []
        let pattern = "%\(searchQuery)%"
        do {
            let query = table.filter(
                titleColumn.like(pattern) || contentColumn.like(pattern)
            ).order(updatedAtColumn.desc)
            for row in try db.prepare(query) {
                if let note = mapRow(row) {
                    notes.append(note)
                }
            }
        } catch {
            logger.error("Failed to search notes: \(error)")
        }
        return notes
    }

    // MARK: - Row Mapping

    private func mapRow(_ row: Row) -> Note? {
        guard let id = UUID(uuidString: row[idColumn]),
              let projectId = UUID(uuidString: row[projectIdColumn])
        else { return nil }

        return Note(
            id: id,
            projectId: projectId,
            title: row[titleColumn],
            content: row[contentColumn],
            isPinned: row[isPinnedColumn],
            sortOrder: row[sortOrderColumn],
            createdAt: row[createdAtColumn],
            updatedAt: row[updatedAtColumn]
        )
    }
}
