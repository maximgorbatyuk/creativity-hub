import Foundation
import SQLite
import os

class TagRepository {
    private let tagsTable = Table("tags")
    private let ideaTagsTable = Table("idea_tags")

    private let idColumn = Expression<String>("id")
    private let nameColumn = Expression<String>("name")
    private let colorColumn = Expression<String>("color")
    private let ideaIdColumn = Expression<String>("idea_id")
    private let tagIdColumn = Expression<String>("tag_id")

    private let db: Connection
    private let logger: Logger

    init(db: Connection, logger: Logger? = nil) {
        self.db = db
        self.logger = logger ?? Logger(
            subsystem: Bundle.main.bundleIdentifier ?? "-",
            category: "TagRepository"
        )
    }

    func fetchAll() -> [Tag] {
        var tags: [Tag] = []
        do {
            for row in try db.prepare(tagsTable.order(nameColumn.asc)) {
                if let tag = mapRow(row) {
                    tags.append(tag)
                }
            }
        } catch {
            logger.error("Failed to fetch all tags: \(error)")
        }
        return tags
    }

    func fetchById(id: UUID) -> Tag? {
        do {
            let query = tagsTable.filter(idColumn == id.uuidString)
            if let row = try db.pluck(query) {
                return mapRow(row)
            }
        } catch {
            logger.error("Failed to fetch tag by id \(id): \(error)")
        }
        return nil
    }

    func fetchTagsForIdea(ideaId: UUID) -> [Tag] {
        var tags: [Tag] = []
        do {
            let query = tagsTable.join(
                ideaTagsTable,
                on: idColumn == tagIdColumn
            ).filter(ideaIdColumn == ideaId.uuidString)
            for row in try db.prepare(query) {
                if let tag = mapRow(row) {
                    tags.append(tag)
                }
            }
        } catch {
            logger.error("Failed to fetch tags for idea \(ideaId): \(error)")
        }
        return tags
    }

    func insert(_ tag: Tag) -> Bool {
        do {
            try db.run(tagsTable.insert(
                idColumn <- tag.id.uuidString,
                nameColumn <- tag.name,
                colorColumn <- tag.color
            ))
            logger.info("Inserted tag: \(tag.id)")
            return true
        } catch {
            logger.error("Failed to insert tag: \(error)")
            return false
        }
    }

    func update(_ tag: Tag) -> Bool {
        let record = tagsTable.filter(idColumn == tag.id.uuidString)
        do {
            try db.run(record.update(
                nameColumn <- tag.name,
                colorColumn <- tag.color
            ))
            logger.info("Updated tag: \(tag.id)")
            return true
        } catch {
            logger.error("Failed to update tag: \(error)")
            return false
        }
    }

    func delete(id: UUID) -> Bool {
        do {
            try db.run(ideaTagsTable.filter(tagIdColumn == id.uuidString).delete())
            try db.run(tagsTable.filter(idColumn == id.uuidString).delete())
            logger.info("Deleted tag: \(id)")
            return true
        } catch {
            logger.error("Failed to delete tag: \(error)")
            return false
        }
    }

    func linkTagToIdea(tagId: UUID, ideaId: UUID) -> Bool {
        do {
            try db.run(ideaTagsTable.insert(
                ideaIdColumn <- ideaId.uuidString,
                tagIdColumn <- tagId.uuidString
            ))
            logger.info("Linked tag \(tagId) to idea \(ideaId)")
            return true
        } catch {
            logger.error("Failed to link tag to idea: \(error)")
            return false
        }
    }

    func unlinkTagFromIdea(tagId: UUID, ideaId: UUID) -> Bool {
        let record = ideaTagsTable.filter(
            ideaIdColumn == ideaId.uuidString && tagIdColumn == tagId.uuidString
        )
        do {
            try db.run(record.delete())
            logger.info("Unlinked tag \(tagId) from idea \(ideaId)")
            return true
        } catch {
            logger.error("Failed to unlink tag from idea: \(error)")
            return false
        }
    }

    func deleteLinksForIdea(ideaId: UUID) -> Bool {
        let records = ideaTagsTable.filter(ideaIdColumn == ideaId.uuidString)
        do {
            try db.run(records.delete())
            return true
        } catch {
            logger.error("Failed to delete tag links for idea: \(error)")
            return false
        }
    }

    // MARK: - Row Mapping

    private func mapRow(_ row: Row) -> Tag? {
        guard let id = UUID(uuidString: row[idColumn]) else { return nil }
        return Tag(
            id: id,
            name: row[nameColumn],
            color: row[colorColumn]
        )
    }
}
