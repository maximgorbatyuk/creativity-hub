import Foundation
import SQLite
import os

class ProjectRepository {
    private let table = Table("projects")

    private let idColumn = Expression<String>("id")
    private let nameColumn = Expression<String>("name")
    private let descriptionColumn = Expression<String?>("description")
    private let coverColorColumn = Expression<String?>("cover_color")
    private let coverImagePathColumn = Expression<String?>("cover_image_path")
    private let statusColumn = Expression<String>("status")
    private let startDateColumn = Expression<Date?>("start_date")
    private let targetDateColumn = Expression<Date?>("target_date")
    private let budgetColumn = Expression<String?>("budget")
    private let budgetCurrencyColumn = Expression<String?>("budget_currency")
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
            category: "ProjectRepository"
        )
    }

    func deleteAll() {
        do {
            try db.run(table.delete())
        } catch {
            logger.error("Failed to delete all projects: \(error)")
        }
    }

    func fetchAll() -> [Project] {
        var projects: [Project] = []
        do {
            let query = table.order(isPinnedColumn.desc, updatedAtColumn.desc)
            for row in try db.prepare(query) {
                if let project = mapRow(row) {
                    projects.append(project)
                }
            }
        } catch {
            logger.error("Failed to fetch all projects: \(error)")
        }
        return projects
    }

    func fetchById(id: UUID) -> Project? {
        do {
            let query = table.filter(idColumn == id.uuidString)
            if let row = try db.pluck(query) {
                return mapRow(row)
            }
        } catch {
            logger.error("Failed to fetch project by id \(id): \(error)")
        }
        return nil
    }

    func fetchByStatus(_ status: ProjectStatus) -> [Project] {
        var projects: [Project] = []
        do {
            let query = table.filter(statusColumn == status.rawValue)
                .order(isPinnedColumn.desc, updatedAtColumn.desc)
            for row in try db.prepare(query) {
                if let project = mapRow(row) {
                    projects.append(project)
                }
            }
        } catch {
            logger.error("Failed to fetch projects by status \(status.rawValue): \(error)")
        }
        return projects
    }

    func insert(_ project: Project) -> Bool {
        do {
            try db.run(table.insert(
                idColumn <- project.id.uuidString,
                nameColumn <- project.name,
                descriptionColumn <- project.projectDescription,
                coverColorColumn <- project.coverColor,
                coverImagePathColumn <- project.coverImagePath,
                statusColumn <- project.status.rawValue,
                startDateColumn <- project.startDate,
                targetDateColumn <- project.targetDate,
                budgetColumn <- project.budget.map { "\($0)" },
                budgetCurrencyColumn <- project.budgetCurrency?.rawValue,
                isPinnedColumn <- project.isPinned,
                sortOrderColumn <- project.sortOrder,
                createdAtColumn <- project.createdAt,
                updatedAtColumn <- project.updatedAt
            ))
            logger.info("Inserted project: \(project.id)")
            return true
        } catch {
            logger.error("Failed to insert project: \(error)")
            return false
        }
    }

    func update(_ project: Project) -> Bool {
        let record = table.filter(idColumn == project.id.uuidString)
        do {
            try db.run(record.update(
                nameColumn <- project.name,
                descriptionColumn <- project.projectDescription,
                coverColorColumn <- project.coverColor,
                coverImagePathColumn <- project.coverImagePath,
                statusColumn <- project.status.rawValue,
                startDateColumn <- project.startDate,
                targetDateColumn <- project.targetDate,
                budgetColumn <- project.budget.map { "\($0)" },
                budgetCurrencyColumn <- project.budgetCurrency?.rawValue,
                isPinnedColumn <- project.isPinned,
                sortOrderColumn <- project.sortOrder,
                updatedAtColumn <- Date()
            ))
            logger.info("Updated project: \(project.id)")
            return true
        } catch {
            logger.error("Failed to update project: \(error)")
            return false
        }
    }

    func delete(id: UUID) -> Bool {
        let record = table.filter(idColumn == id.uuidString)
        do {
            try db.run(record.delete())
            logger.info("Deleted project: \(id)")
            return true
        } catch {
            logger.error("Failed to delete project: \(error)")
            return false
        }
    }

    func count() -> Int {
        do {
            return try db.scalar(table.count)
        } catch {
            logger.error("Failed to count projects: \(error)")
            return 0
        }
    }

    func search(query searchQuery: String) -> [Project] {
        var projects: [Project] = []
        let pattern = "%\(searchQuery)%"
        do {
            let query = table.filter(
                nameColumn.like(pattern) || descriptionColumn.like(pattern)
            ).order(updatedAtColumn.desc)
            for row in try db.prepare(query) {
                if let project = mapRow(row) {
                    projects.append(project)
                }
            }
        } catch {
            logger.error("Failed to search projects: \(error)")
        }
        return projects
    }

    func togglePin(id: UUID, isPinned: Bool) -> Bool {
        let record = table.filter(idColumn == id.uuidString)
        do {
            try db.run(record.update(
                isPinnedColumn <- isPinned,
                updatedAtColumn <- Date()
            ))
            logger.info("Toggled pin for project \(id): \(isPinned)")
            return true
        } catch {
            logger.error("Failed to toggle pin for project \(id): \(error)")
            return false
        }
    }

    func updateStatus(id: UUID, status: ProjectStatus) -> Bool {
        let record = table.filter(idColumn == id.uuidString)
        do {
            try db.run(record.update(
                statusColumn <- status.rawValue,
                updatedAtColumn <- Date()
            ))
            logger.info("Updated status for project \(id): \(status.rawValue)")
            return true
        } catch {
            logger.error("Failed to update status for project \(id): \(error)")
            return false
        }
    }

    func touchUpdatedAt(id: UUID) {
        let record = table.filter(idColumn == id.uuidString)
        do {
            try db.run(record.update(updatedAtColumn <- Date()))
        } catch {
            logger.error("Failed to touch updatedAt for project \(id): \(error)")
        }
    }

    // MARK: - Row Mapping

    private func mapRow(_ row: Row) -> Project? {
        guard let id = UUID(uuidString: row[idColumn]) else { return nil }

        let budget: Decimal? = row[budgetColumn].flatMap { Decimal(string: $0) }
        let budgetCurrency: Currency? = row[budgetCurrencyColumn].flatMap { Currency(rawValue: $0) }
        let status = ProjectStatus(rawValue: row[statusColumn]) ?? .active

        return Project(
            id: id,
            name: row[nameColumn],
            projectDescription: row[descriptionColumn],
            coverColor: row[coverColorColumn],
            coverImagePath: row[coverImagePathColumn],
            status: status,
            startDate: row[startDateColumn],
            targetDate: row[targetDateColumn],
            budget: budget,
            budgetCurrency: budgetCurrency,
            isPinned: row[isPinnedColumn],
            sortOrder: row[sortOrderColumn],
            createdAt: row[createdAtColumn],
            updatedAt: row[updatedAtColumn]
        )
    }
}
