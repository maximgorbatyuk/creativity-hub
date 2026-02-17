import Combine
import Foundation

final class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()

    @Published var currentLanguage: AppLanguage

    private init() {
        if let repo = DatabaseManager.shared.userSettingsRepository {
            self.currentLanguage = repo.fetchLanguage()
        } else {
            self.currentLanguage = .en
        }
    }

    func setLanguage(_ language: AppLanguage) {
        currentLanguage = language
        DatabaseManager.shared.userSettingsRepository?.upsertLanguage(language)
    }

    func localizedString(forKey key: String) -> String {
        localizedString(forKey: key, language: currentLanguage)
    }

    func localizedString(forKey key: String, language: AppLanguage) -> String {
        if let path = Bundle.main.path(forResource: language.rawValue, ofType: "lproj"),
           let bundle = Bundle(path: path)
        {
            return bundle.localizedString(forKey: key, value: key, table: nil)
        }
        return Bundle.main.localizedString(forKey: key, value: key, table: nil)
    }
}
