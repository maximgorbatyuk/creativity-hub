import Foundation
import SwiftUI

enum UserSettingKey: String {
    case currency = "currency"
    case language = "language"
    case colorScheme = "color_scheme"
    case userId = "user_id"
    case activityLogCleanupLastRunAt = "activity_log_cleanup_last_run_at"
    case activityLogCleanupLastRemovedCount = "activity_log_cleanup_last_removed_count"
}

enum AppLanguage: String, CaseIterable, Codable {
    case en
    case ru
    case kk

    // Displayed in native language so users can identify their language regardless of current app locale.
    var displayName: String {
        switch self {
        case .en: return "English"
        case .ru: return "Русский"
        case .kk: return "Қазақша"
        }
    }

    var flag: String {
        switch self {
        case .en: return "🇺🇸"
        case .ru: return "🇷🇺"
        case .kk: return "🇰🇿"
        }
    }
}

enum AppColorScheme: String, CaseIterable, Codable {
    case system
    case light
    case dark

    var displayName: String {
        switch self {
        case .system: return L("settings.color_scheme.system")
        case .light: return L("settings.color_scheme.light")
        case .dark: return L("settings.color_scheme.dark")
        }
    }

    var icon: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}
