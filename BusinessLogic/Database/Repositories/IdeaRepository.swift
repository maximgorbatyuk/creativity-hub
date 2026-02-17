import Foundation
import SQLite
import os

class IdeaRepository {
    private let table = Table("ideas")

    private let idColumn = Expression<String>("id")
    private let projectIdColumn = Expression<String>("project_id")
    private let urlColumn = Expression<String?>("url")
    private let titleColumn = Expression<String>("title")
    private let thumbnailUrlColumn = Expression<String?>("thumbnail_url")
    private let sourceDomainColumn = Expression<String?>("source_domain")
    private let sourceTypeColumn = Expression<String>("source_type")
    private let notesColumn = Expression<String?>("notes")
    private let createdAtColumn = Expression<Date>("created_at")
    private let updatedAtColumn = Expression<Date>("updated_at")

    private let db: Connection
    private let logger: Logger

    init(db: Connection, logger: Logger? = nil) {
        self.db = db
        self.logger = logger ?? Logger(
            subsystem: Bundle.main.bundleIdentifier ?? "-",
            category: "IdeaRepository"
        )
    }

    func fetchByProjectId(projectId: UUID) -> [Idea] {
        var ideas: [Idea] = []
        do {
            let query = table.filter(projectIdColumn == projectId.uuidString)
                .order(createdAtColumn.desc)
            for row in try db.prepare(query) {
                if let idea = mapRow(row) {
                    ideas.append(idea)
                }
            }
        } catch {
            logger.error("Failed to fetch ideas for project \(projectId): \(error)")
        }
        return ideas
    }

    func fetchById(id: UUID) -> Idea? {
        do {
            let query = table.filter(idColumn == id.uuidString)
            if let row = try db.pluck(query) {
                return mapRow(row)
            }
        } catch {
            logger.error("Failed to fetch idea by id \(id): \(error)")
        }
        return nil
    }

    func insert(_ idea: Idea) -> Bool {
        do {
            try db.run(table.insert(
                idColumn <- idea.id.uuidString,
                projectIdColumn <- idea.projectId.uuidString,
                urlColumn <- idea.url,
                titleColumn <- idea.title,
                thumbnailUrlColumn <- idea.thumbnailUrl,
                sourceDomainColumn <- idea.sourceDomain,
                sourceTypeColumn <- idea.sourceType.rawValue,
                notesColumn <- idea.notes,
                createdAtColumn <- idea.createdAt,
                updatedAtColumn <- idea.updatedAt
            ))
            logger.info("Inserted idea: \(idea.id)")
            return true
        } catch {
            logger.error("Failed to insert idea: \(error)")
            return false
        }
    }

    func update(_ idea: Idea) -> Bool {
        let record = table.filter(idColumn == idea.id.uuidString)
        do {
            try db.run(record.update(
                urlColumn <- idea.url,
                titleColumn <- idea.title,
                thumbnailUrlColumn <- idea.thumbnailUrl,
                sourceDomainColumn <- idea.sourceDomain,
                sourceTypeColumn <- idea.sourceType.rawValue,
                notesColumn <- idea.notes,
                updatedAtColumn <- Date()
            ))
            logger.info("Updated idea: \(idea.id)")
            return true
        } catch {
            logger.error("Failed to update idea: \(error)")
            return false
        }
    }

    func delete(id: UUID) -> Bool {
        let record = table.filter(idColumn == id.uuidString)
        do {
            try db.run(record.delete())
            logger.info("Deleted idea: \(id)")
            return true
        } catch {
            logger.error("Failed to delete idea: \(error)")
            return false
        }
    }

    func deleteByProjectId(projectId: UUID) -> Bool {
        let records = table.filter(projectIdColumn == projectId.uuidString)
        do {
            try db.run(records.delete())
            logger.info("Deleted ideas for project: \(projectId)")
            return true
        } catch {
            logger.error("Failed to delete ideas for project: \(error)")
            return false
        }
    }

    func countByProjectId(projectId: UUID) -> Int {
        do {
            return try db.scalar(table.filter(projectIdColumn == projectId.uuidString).count)
        } catch {
            logger.error("Failed to count ideas: \(error)")
            return 0
        }
    }

    func search(query searchQuery: String) -> [Idea] {
        var ideas: [Idea] = []
        let pattern = "%\(searchQuery)%"
        do {
            let query = table.filter(
                titleColumn.like(pattern) || notesColumn.like(pattern) || urlColumn.like(pattern)
            ).order(updatedAtColumn.desc)
            for row in try db.prepare(query) {
                if let idea = mapRow(row) {
                    ideas.append(idea)
                }
            }
        } catch {
            logger.error("Failed to search ideas: \(error)")
        }
        return ideas
    }

    // MARK: - Row Mapping

    private func mapRow(_ row: Row) -> Idea? {
        guard let id = UUID(uuidString: row[idColumn]),
              let projectId = UUID(uuidString: row[projectIdColumn])
        else { return nil }

        let sourceType = IdeaSourceType(rawValue: row[sourceTypeColumn]) ?? .other

        return Idea(
            id: id,
            projectId: projectId,
            url: row[urlColumn],
            title: row[titleColumn],
            thumbnailUrl: row[thumbnailUrlColumn],
            sourceDomain: row[sourceDomainColumn],
            sourceType: sourceType,
            notes: row[notesColumn],
            createdAt: row[createdAtColumn],
            updatedAt: row[updatedAtColumn]
        )
    }
}
