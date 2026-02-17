import Foundation
import SwiftUI

@Observable
final class UserSettingsViewModel {
    var defaultCurrency: Currency
    var selectedLanguage: AppLanguage
    var selectedColorScheme: AppColorScheme

    private let userSettingsRepository: UserSettingsRepository?

    var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "-"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "-"
        return "\(version) (\(build))"
    }

    var developerName: String {
        Bundle.main.object(forInfoDictionaryKey: "DeveloperName") as? String ?? ""
    }

    var telegramLink: String {
        Bundle.main.object(forInfoDictionaryKey: "DeveloperTelegramLink") as? String ?? ""
    }

    init(db: DatabaseManager = .shared) {
        self.userSettingsRepository = db.userSettingsRepository
        self.defaultCurrency = userSettingsRepository?.fetchCurrency() ?? .usd
        self.selectedLanguage = userSettingsRepository?.fetchLanguage() ?? .en
        self.selectedColorScheme = userSettingsRepository?.fetchColorScheme() ?? .system
    }

    func saveDefaultCurrency(_ currency: Currency) {
        defaultCurrency = currency
        userSettingsRepository?.upsertCurrency(currency.rawValue)
    }

    func saveLanguage(_ language: AppLanguage) {
        selectedLanguage = language
        LocalizationManager.shared.setLanguage(language)
    }

    func saveColorScheme(_ scheme: AppColorScheme) {
        selectedColorScheme = scheme
        userSettingsRepository?.upsertColorScheme(scheme)

        NotificationCenter.default.post(
            name: .appColorSchemeDidChange,
            object: nil,
            userInfo: ["colorScheme": scheme.rawValue]
        )
    }
}
