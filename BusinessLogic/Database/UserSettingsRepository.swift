import Foundation
import SQLite
import os

class UserSettingsRepository {
    private let table = Table("user_settings")

    private let idColumn = Expression<Int64>("id")
    private let keyColumn = Expression<String>("key")
    private let valueColumn = Expression<String>("value")

    private let db: Connection
    private let logger: Logger
    private let dateFormatterWithFractionalSeconds: ISO8601DateFormatter
    private let dateFormatter: ISO8601DateFormatter

    init(db: Connection, logger: Logger? = nil) {
        self.db = db
        self.logger = logger ?? Logger(
            subsystem: Bundle.main.bundleIdentifier ?? "-",
            category: "UserSettingsRepository"
        )

        let formatterWithFractionalSeconds = ISO8601DateFormatter()
        formatterWithFractionalSeconds.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        self.dateFormatterWithFractionalSeconds = formatterWithFractionalSeconds

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        self.dateFormatter = formatter
    }

    func createTable() {
        do {
            try db.run(table.create(ifNotExists: true) { t in
                t.column(idColumn, primaryKey: .autoincrement)
                t.column(keyColumn, unique: true)
                t.column(valueColumn)
            })
        } catch {
            logger.error("Failed to create user_settings table: \(error)")
        }
    }

    // MARK: - Generic Access

    func fetchValue(for key: String) -> String? {
        do {
            let query = table.filter(keyColumn == key)
            if let row = try db.pluck(query) {
                return row[valueColumn]
            }
        } catch {
            logger.error("Failed to fetch setting '\(key)': \(error)")
        }
        return nil
    }

    @discardableResult
    func upsertValue(key: String, value: String) -> Bool {
        do {
            let query = table.filter(keyColumn == key)
            if try db.pluck(query) != nil {
                try db.run(query.update(valueColumn <- value))
            } else {
                try db.run(table.insert(keyColumn <- key, valueColumn <- value))
            }
            return true
        } catch {
            logger.error("Failed to upsert setting '\(key)': \(error)")
            return false
        }
    }

    func fetchDateValue(for key: String) -> Date? {
        guard let value = fetchValue(for: key) else {
            return nil
        }

        if let parsedWithFractionalSeconds = dateFormatterWithFractionalSeconds.date(from: value) {
            return parsedWithFractionalSeconds
        }

        return dateFormatter.date(from: value)
    }

    @discardableResult
    func upsertDateValue(key: String, value: Date) -> Bool {
        let encodedValue = dateFormatterWithFractionalSeconds.string(from: value)
        return upsertValue(key: key, value: encodedValue)
    }

    // MARK: - Currency

    func fetchCurrency() -> Currency {
        guard let raw = fetchValue(for: UserSettingKey.currency.rawValue),
              let currency = Currency(rawValue: raw)
        else {
            return .usd
        }
        return currency
    }

    @discardableResult
    func upsertCurrency(_ currencyValue: String) -> Bool {
        upsertValue(key: UserSettingKey.currency.rawValue, value: currencyValue)
    }

    // MARK: - Language

    func fetchLanguage() -> AppLanguage {
        guard let raw = fetchValue(for: UserSettingKey.language.rawValue),
              let language = AppLanguage(rawValue: raw)
        else {
            return .en
        }
        return language
    }

    @discardableResult
    func upsertLanguage(_ language: AppLanguage) -> Bool {
        upsertValue(key: UserSettingKey.language.rawValue, value: language.rawValue)
    }

    // MARK: - Color Scheme

    func fetchColorScheme() -> AppColorScheme {
        guard let raw = fetchValue(for: UserSettingKey.colorScheme.rawValue),
              let scheme = AppColorScheme(rawValue: raw)
        else {
            return .system
        }
        return scheme
    }

    @discardableResult
    func upsertColorScheme(_ scheme: AppColorScheme) -> Bool {
        upsertValue(key: UserSettingKey.colorScheme.rawValue, value: scheme.rawValue)
    }

    // MARK: - Fetch All

    func fetchAll() -> [(id: Int64, key: String, value: String)] {
        do {
            return try db.prepare(table).map { row in
                (id: row[idColumn], key: row[keyColumn], value: row[valueColumn])
            }
        } catch {
            logger.error("Failed to fetch all settings: \(error)")
            return []
        }
    }

    // MARK: - User ID

    func fetchOrGenerateUserId() -> String {
        if let existing = fetchValue(for: UserSettingKey.userId.rawValue) {
            return existing
        }
        let newId = UUID().uuidString
        upsertValue(key: UserSettingKey.userId.rawValue, value: newId)
        return newId
    }

    // MARK: - Activity Log Cleanup Metadata

    func fetchActivityLogCleanupLastRunAt() -> Date? {
        fetchDateValue(for: UserSettingKey.activityLogCleanupLastRunAt.rawValue)
    }

    @discardableResult
    func upsertActivityLogCleanupLastRunAt(_ date: Date) -> Bool {
        upsertDateValue(key: UserSettingKey.activityLogCleanupLastRunAt.rawValue, value: date)
    }

    func fetchActivityLogCleanupLastRemovedCount() -> Int? {
        guard let value = fetchValue(for: UserSettingKey.activityLogCleanupLastRemovedCount.rawValue) else {
            return nil
        }

        return Int(value)
    }

    @discardableResult
    func upsertActivityLogCleanupLastRemovedCount(_ count: Int) -> Bool {
        upsertValue(
            key: UserSettingKey.activityLogCleanupLastRemovedCount.rawValue,
            value: String(count)
        )
    }
}
