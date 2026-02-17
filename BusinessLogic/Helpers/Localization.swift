import Foundation

/// Global localization helper function.
func L(_ key: String) -> String {
    LocalizationManager.shared.localizedString(forKey: key)
}

func L(_ key: String, language: AppLanguage) -> String {
    LocalizationManager.shared.localizedString(forKey: key, language: language)
}
