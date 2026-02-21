import Foundation
import os

protocol AppVersionCheckerProtocol {
    func checkAppStoreVersion() async -> Bool?
}

final class AppVersionChecker: AppVersionCheckerProtocol {
    private let environment: EnvironmentService
    private let logger: Logger

    init(
        environment: EnvironmentService,
        logger: Logger? = nil
    ) {
        self.environment = environment
        self.logger = logger ?? Logger(
            subsystem: environment.getAppBundleId(),
            category: "AppVersionChecker"
        )
    }

    func checkAppStoreVersion() async -> Bool? {
        let currentVersionWithBuild = environment.getAppVisibleVersion()
        let currentVersion = currentVersionWithBuild.split(separator: " ").first.map(String.init) ?? currentVersionWithBuild

        let today = Date()
        let currentWeekOfYear = Calendar.current.component(.weekOfYear, from: today)
        let currentYear = Calendar.current.component(.year, from: today)
        let dayOfWeek = Calendar.current.component(.weekday, from: today)
        let queryParam = "\(currentYear).\(currentWeekOfYear).\(dayOfWeek)"

        guard let appStoreId = environment.getAppStoreId(), !appStoreId.isEmpty,
              let url = URL(string: "https://itunes.apple.com/lookup?id=\(appStoreId)&current=\(currentVersion)&now=\(queryParam)")
        else {
            return nil
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            let results = json?["results"] as? [[String: Any]]
            let appStoreVersion = results?.first?["version"] as? String ?? ""

            if appStoreVersion.isEmpty {
                logger.info("No version info found in App Store response")
                return nil
            }

            return currentVersion != appStoreVersion
        } catch {
            logger.error("Version check failed: \(error.localizedDescription)")
            return nil
        }
    }
}
