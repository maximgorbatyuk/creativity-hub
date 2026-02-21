import Foundation
import Combine

class EnvironmentService: ObservableObject {

    static let shared = EnvironmentService()

    private var appVisibleVersion: String?
    private var appStoreId: String?
    private var appBundleId: String?
    private var appDisplayName: String?
    private var developerName: String?
    private var gitHubRepositoryUrl: String?
    private var buildEnvironment: String?
    private var developerTelegramLink: String?
    private var appStoreAppLink: String?
    private var appGroupIdentifier: String?

    private init() {}

    func getAppVisibleVersion() -> String {
        if let appVisibleVersion {
            return appVisibleVersion
        }

        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "-"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "-"
        let value = "\(version) (\(build))"
        appVisibleVersion = value
        return value
    }

    func getAppStoreId() -> String? {
        if let appStoreId {
            return appStoreId
        }

        let value = Bundle.main.object(forInfoDictionaryKey: "AppStoreId") as? String
        appStoreId = value
        return value
    }

    func getAppBundleId() -> String {
        if let appBundleId {
            return appBundleId
        }

        let value = Bundle.main.bundleIdentifier ?? "-"
        appBundleId = value
        return value
    }

    func getAppDisplayName() -> String {
        if let appDisplayName {
            return appDisplayName
        }

        let value = (Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String)
            ?? (Bundle.main.infoDictionary?["CFBundleName"] as? String)
            ?? "-"
        appDisplayName = value
        return value
    }

    func getDeveloperName() -> String {
        if let developerName {
            return developerName
        }

        let value = Bundle.main.object(forInfoDictionaryKey: "DeveloperName") as? String ?? ""
        developerName = value
        return value
    }

    func getGitHubRepositoryUrl() -> String {
        if let gitHubRepositoryUrl {
            return gitHubRepositoryUrl
        }

        let value = Bundle.main.object(forInfoDictionaryKey: "GithubRepoUrl") as? String ?? ""
        gitHubRepositoryUrl = value
        return value
    }

    func getBuildEnvironment() -> String {
        if let buildEnvironment {
            return buildEnvironment
        }

        let value = Bundle.main.object(forInfoDictionaryKey: "BuildEnvironment") as? String ?? ""
        buildEnvironment = value
        return value
    }

    func getDeveloperTelegramLink() -> String {
        if let developerTelegramLink {
            return developerTelegramLink
        }

        let value = Bundle.main.object(forInfoDictionaryKey: "DeveloperTelegramLink") as? String ?? ""
        developerTelegramLink = value
        return value
    }

    func getAppStoreAppLink() -> String {
        if let appStoreAppLink {
            return appStoreAppLink
        }

        guard let appStoreId = getAppStoreId(), !appStoreId.isEmpty else {
            return ""
        }

        let value = "https://apps.apple.com/app/id\(appStoreId)"
        appStoreAppLink = value
        return value
    }

    func getAppGroupIdentifier() -> String? {
        if let appGroupIdentifier {
            return appGroupIdentifier
        }

        let value = Bundle.main.object(forInfoDictionaryKey: "AppGroupIdentifier") as? String
        appGroupIdentifier = value
        return value
    }

    func isDevelopmentMode() -> Bool {
        getBuildEnvironment() == "dev"
    }

    func getOsVersion() -> String {
        let version = ProcessInfo.processInfo.operatingSystemVersion
        return "\(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"
    }

    func getAppLanguage() -> String {
        Locale.current.language.languageCode?.identifier ?? "unknown"
    }
}
