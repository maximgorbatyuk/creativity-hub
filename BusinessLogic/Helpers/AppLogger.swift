import Foundation
import os

final class AppLogger: Sendable {
    static let shared = AppLogger()

    private let logger: Logger

    init(category: String = "General") {
        self.logger = Logger(
            subsystem: Bundle.main.bundleIdentifier ?? "dev.mgorbatyuk.CreativityHub",
            category: category
        )
    }

    func info(_ message: String) {
        logger.info("\(message, privacy: .public)")
    }

    func error(_ message: String) {
        logger.error("\(message, privacy: .public)")
    }

    func warning(_ message: String) {
        logger.warning("\(message, privacy: .public)")
    }

    func debug(_ message: String) {
        logger.debug("\(message, privacy: .public)")
    }

    static func logger(for category: String) -> AppLogger {
        AppLogger(category: category)
    }
}
