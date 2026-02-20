import BackgroundTasks
import Foundation
import os

/// Manages automatic iCloud backup scheduling and execution.
@MainActor
final class BackgroundTaskManager {
    // MARK: - Constants

    /// Must match BGTaskSchedulerPermittedIdentifiers in Info.plist.
    static let dailyBackupTaskIdentifier = "dev.mgorbatyuk.CreativityHub.backup"

    private enum UserDefaultsKey {
        static let automaticBackupEnabled = "creativityhub.automaticBackupEnabled"
        static let lastAutomaticBackupDate = "creativityhub.lastAutomaticBackupDate"
        static let lastBackupAttemptDate = "creativityhub.lastBackupAttemptDate"
        static let pendingRetry = "creativityhub.pendingBackupRetry"
    }

    // MARK: - Dependencies

    static let shared = BackgroundTaskManager()

    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "dev.mgorbatyuk.CreativityHub",
        category: "BackgroundTaskManager"
    )
    private let backupService: BackupService

    // MARK: - State

    var isAutomaticBackupEnabled: Bool {
        didSet {
            UserDefaults.standard.set(
                isAutomaticBackupEnabled,
                forKey: UserDefaultsKey.automaticBackupEnabled
            )

            if isAutomaticBackupEnabled {
                scheduleNextBackup()
            } else {
                pendingRetry = false
                cancelAllBackupTasks()
            }
        }
    }

    var lastAutomaticBackupDate: Date? {
        didSet {
            if let date = lastAutomaticBackupDate {
                UserDefaults.standard.set(
                    date,
                    forKey: UserDefaultsKey.lastAutomaticBackupDate
                )
            } else {
                UserDefaults.standard.removeObject(
                    forKey: UserDefaultsKey.lastAutomaticBackupDate
                )
            }
        }
    }

    private var pendingRetry: Bool {
        get { UserDefaults.standard.bool(forKey: UserDefaultsKey.pendingRetry) }
        set { UserDefaults.standard.set(newValue, forKey: UserDefaultsKey.pendingRetry) }
    }

    // MARK: - Init

    private init(backupService: BackupService? = nil) {
        self.backupService = backupService ?? BackupService.shared
        self.isAutomaticBackupEnabled = UserDefaults.standard.bool(
            forKey: UserDefaultsKey.automaticBackupEnabled
        )
        self.lastAutomaticBackupDate = UserDefaults.standard.object(
            forKey: UserDefaultsKey.lastAutomaticBackupDate
        ) as? Date
    }

    // MARK: - Registration

    func registerBackgroundTasks() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: Self.dailyBackupTaskIdentifier,
            using: nil
        ) { [weak self] task in
            guard let self else {
                task.setTaskCompleted(success: false)
                return
            }

            self.logger.info("Automatic backup background task started")

            task.expirationHandler = {
                self.logger.warning("Automatic backup background task expired")
                task.setTaskCompleted(success: false)
            }

            Task { @MainActor in
                await self.handleBackgroundBackup(task: task)
            }
        }

        logger.info("Automatic backup background task registered")
    }

    // MARK: - Scheduling

    func scheduleNextBackup() {
        guard isAutomaticBackupEnabled else {
            logger.info("Automatic backup disabled, schedule skipped")
            return
        }

        let calendar = Calendar.current
        let now = Date()

        guard var nextMidnight = calendar.date(byAdding: .day, value: 1, to: now) else {
            logger.error("Failed to calculate next midnight")
            return
        }

        let components = calendar.dateComponents([.year, .month, .day], from: nextMidnight)
        guard let midnight = calendar.date(from: components) else {
            logger.error("Failed to normalize midnight date")
            return
        }

        nextMidnight = midnight

        let request = BGAppRefreshTaskRequest(identifier: Self.dailyBackupTaskIdentifier)
        request.earliestBeginDate = nextMidnight

        do {
            try BGTaskScheduler.shared.submit(request)
            logger.info("Next automatic backup scheduled for: \(nextMidnight)")
        } catch {
            logger.error("Failed to schedule automatic backup: \(error.localizedDescription)")
            pendingRetry = true
        }
    }

    func cancelAllBackupTasks() {
        BGTaskScheduler.shared.cancel(
            taskRequestWithIdentifier: Self.dailyBackupTaskIdentifier
        )
        logger.info("Cancelled automatic backup tasks")
    }

    // MARK: - Retry

    func retryIfNeeded() async {
        guard isAutomaticBackupEnabled, pendingRetry else {
            return
        }

        logger.info("Retrying automatic backup")
        await performSilentBackup()
    }

    // MARK: - Internal backup flow

    private func handleBackgroundBackup(task: BGTask) async {
        let success = await performSilentBackup()
        scheduleNextBackup()
        task.setTaskCompleted(success: success)
    }

    @discardableResult
    private func performSilentBackup() async -> Bool {
        UserDefaults.standard.set(Date(), forKey: UserDefaultsKey.lastBackupAttemptDate)

        guard backupService.isiCloudAvailable() else {
            logger.warning("iCloud unavailable, automatic backup skipped")
            pendingRetry = true
            return false
        }

        do {
            let backupInfo = try await backupService.createiCloudBackup()
            lastAutomaticBackupDate = backupInfo.createdAt
            pendingRetry = false
            logger.info("Automatic backup succeeded: \(backupInfo.fileName)")
            return true
        } catch {
            logger.error("Automatic backup failed: \(error.localizedDescription)")
            pendingRetry = true
            return false
        }
    }
}
