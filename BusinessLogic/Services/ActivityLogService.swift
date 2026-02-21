import Foundation
import os

final class ActivityLogService {
    static let shared = ActivityLogService()

    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "-",
        category: "ActivityLogService"
    )

    private var repository: ActivityLogRepository? {
        DatabaseManager.shared.activityLogRepository
    }

    private init() {}

    func log(
        projectId: UUID,
        entityType: ActivityEntityType,
        actionType: ActivityActionType,
        createdAt: Date = Date()
    ) {
        let activityLog = ActivityLog(
            projectId: projectId,
            entityType: entityType,
            actionType: actionType,
            createdAt: createdAt
        )

        guard repository?.insert(activityLog) == true else {
            logger.error("Failed to log activity for project \(projectId)")
            return
        }
    }

    @discardableResult
    func cleanupOlderThanSixMonths(referenceDate: Date = Date()) -> Int {
        let calendar = Calendar.current
        let cutoffDate = calendar.date(byAdding: .month, value: -6, to: referenceDate) ?? referenceDate
        return repository?.deleteOlderThan(cutoffDate) ?? 0
    }
}
