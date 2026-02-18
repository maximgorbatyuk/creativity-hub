import Foundation

/// Global localization helper function.
func L(_ key: String) -> String {
    LocalizationManager.shared.localizedString(forKey: key)
}

func L(_ key: String, language: AppLanguage) -> String {
    LocalizationManager.shared.localizedString(forKey: key, language: language)
}

func L(_ key: String, _ args: CVarArg...) -> String {
    let format = LocalizationManager.shared.localizedString(forKey: key)
    return String(format: format, arguments: args)
}
