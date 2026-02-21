import Foundation

final class MainTabViewModel {
    private let appVersionChecker: AppVersionCheckerProtocol

    init(appVersionChecker: AppVersionCheckerProtocol) {
        self.appVersionChecker = appVersionChecker
    }

    func checkAppVersion() async -> Bool? {
        await appVersionChecker.checkAppStoreVersion()
    }
}
