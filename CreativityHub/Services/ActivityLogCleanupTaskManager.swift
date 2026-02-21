import BackgroundTasks
import Foundation
import os

@MainActor
final class ActivityLogCleanupTaskManager {
    static let cleanupTaskIdentifier = "dev.mgorbatyuk.CreativityHub.activitylogcleanup"

    static let shared = ActivityLogCleanupTaskManager()

    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "dev.mgorbatyuk.CreativityHub",
        category: "ActivityLogCleanupTaskManager"
    )

    private let activityLogService: ActivityLogService
    private var userSettingsRepository: UserSettingsRepository? {
        DatabaseManager.shared.userSettingsRepository
    }

    private init(activityLogService: ActivityLogService = .shared) {
        self.activityLogService = activityLogService
    }

    func registerBackgroundTasks() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: Self.cleanupTaskIdentifier,
            using: nil
        ) { [weak self] task in
            guard let self else {
                task.setTaskCompleted(success: false)
                return
            }

            self.logger.info("Activity log cleanup background task started")

            task.expirationHandler = {
                self.logger.warning("Activity log cleanup background task expired")
                task.setTaskCompleted(success: false)
            }

            Task { @MainActor in
                self.handleBackgroundCleanup(task: task)
            }
        }

        logger.info("Activity log cleanup background task registered")
    }

    func scheduleNextCleanup() {
        let request = BGAppRefreshTaskRequest(identifier: Self.cleanupTaskIdentifier)
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: Date())
        request.earliestBeginDate = calendar.date(byAdding: .day, value: 1, to: todayStart)

        do {
            try BGTaskScheduler.shared.submit(request)
            logger.info("Activity log cleanup task scheduled")
        } catch {
            logger.error("Failed to schedule activity log cleanup task: \(error.localizedDescription)")
        }
    }

    func runForegroundCleanupIfNeeded() {
        _ = performCleanupIfNeeded()
    }

    private func handleBackgroundCleanup(task: BGTask) {
        let success = performCleanupIfNeeded()
        scheduleNextCleanup()
        task.setTaskCompleted(success: success)
    }

    @discardableResult
    private func performCleanupIfNeeded(referenceDate: Date = Date()) -> Bool {
        guard shouldRunCleanup(on: referenceDate) else {
            logger.info("Activity log cleanup skipped, already completed today")
            return true
        }

        return performCleanup(referenceDate: referenceDate)
    }

    private func shouldRunCleanup(on referenceDate: Date) -> Bool {
        guard let lastCleanupDate = userSettingsRepository?.fetchActivityLogCleanupLastRunAt() else {
            return true
        }

        return !Calendar.current.isDate(lastCleanupDate, inSameDayAs: referenceDate)
    }

    @discardableResult
    private func performCleanup(referenceDate: Date) -> Bool {
        let deletedCount = activityLogService.cleanupOlderThanSixMonths(referenceDate: referenceDate)
        let savedCleanupDate = userSettingsRepository?.upsertActivityLogCleanupLastRunAt(referenceDate) ?? false
        let savedDeletedCount = userSettingsRepository?.upsertActivityLogCleanupLastRemovedCount(deletedCount) ?? false

        guard savedCleanupDate && savedDeletedCount else {
            logger.error("Activity log cleanup completed but failed to store cleanup metadata")
            return false
        }

        logger.info("Activity log cleanup completed, removed \(deletedCount) records")
        return true
    }
}
