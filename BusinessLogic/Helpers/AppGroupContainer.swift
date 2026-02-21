import Foundation
import os

enum AppGroupContainer {
    private static let logger = Logger(subsystem: "AppGroupContainer", category: "Storage")

    static var identifier: String {
        guard let identifier = EnvironmentService.shared.getAppGroupIdentifier(), !identifier.isEmpty else {
            logger.error("AppGroupIdentifier not found in Info.plist")
            fatalError("AppGroupIdentifier not found in Info.plist. Check xcconfig setup.")
        }
        return identifier
    }

    static var containerURL: URL {
        guard let url = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: identifier)
        else {
            logger.error("App Group '\(identifier)' not configured. Check entitlements.")
            fatalError("App Group '\(identifier)' not configured")
        }
        return url
    }

    static var databaseURL: URL {
        containerURL.appendingPathComponent("creativity_hub.sqlite3")
    }

    static var documentsURL: URL {
        let url = containerURL.appendingPathComponent("CreativityHubDocuments")
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    static var isConfigured: Bool {
        guard let identifier = EnvironmentService.shared.getAppGroupIdentifier(), !identifier.isEmpty else {
            return false
        }
        return FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: identifier) != nil
    }
}
