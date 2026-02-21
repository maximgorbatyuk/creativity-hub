import Foundation

struct ExportData: Codable {
    let metadata: ExportMetadata
    let userSettings: ExportUserSettings
    let projects: [Project]?
    let checklists: [Checklist]?
    let checklistItems: [ChecklistItem]?
    let ideas: [Idea]?
    let tags: [Tag]?
    let ideaTagLinks: [IdeaTagLink]?
    let expenses: [Expense]?
    let expenseCategories: [ExpenseCategory]?
    let notes: [Note]?
    let documents: [Document]?
    let reminders: [Reminder]?
    let workLogs: [WorkLog]?

    init(
        metadata: ExportMetadata,
        userSettings: ExportUserSettings,
        projects: [Project]? = nil,
        checklists: [Checklist]? = nil,
        checklistItems: [ChecklistItem]? = nil,
        ideas: [Idea]? = nil,
        tags: [Tag]? = nil,
        ideaTagLinks: [IdeaTagLink]? = nil,
        expenses: [Expense]? = nil,
        expenseCategories: [ExpenseCategory]? = nil,
        notes: [Note]? = nil,
        documents: [Document]? = nil,
        reminders: [Reminder]? = nil,
        workLogs: [WorkLog]? = nil
    ) {
        self.metadata = metadata
        self.userSettings = userSettings
        self.projects = projects
        self.checklists = checklists
        self.checklistItems = checklistItems
        self.ideas = ideas
        self.tags = tags
        self.ideaTagLinks = ideaTagLinks
        self.expenses = expenses
        self.expenseCategories = expenseCategories
        self.notes = notes
        self.documents = documents
        self.reminders = reminders
        self.workLogs = workLogs
    }
}

struct ExportMetadata: Codable {
    let createdAt: Date
    let appVersion: String
    let deviceName: String
    let databaseSchemaVersion: Int

    init(
        createdAt: Date = Date(),
        appVersion: String,
        deviceName: String,
        databaseSchemaVersion: Int
    ) {
        self.createdAt = createdAt
        self.appVersion = appVersion
        self.deviceName = deviceName
        self.databaseSchemaVersion = databaseSchemaVersion
    }
}

struct ExportUserSettings: Codable {
    let preferredCurrency: String
    let preferredLanguage: String
    let preferredColorScheme: String

    init(currency: Currency, language: AppLanguage, colorScheme: AppColorScheme) {
        self.preferredCurrency = currency.rawValue
        self.preferredLanguage = language.rawValue
        self.preferredColorScheme = colorScheme.rawValue
    }
}

struct IdeaTagLink: Codable {
    let ideaId: UUID
    let tagId: UUID
}

// MARK: - Validation Errors

enum ExportValidationError: LocalizedError {
    case invalidJSON
    case missingMetadata
    case newerSchemaVersion(current: Int, file: Int)
    case corruptedData

    var errorDescription: String? {
        switch self {
        case .invalidJSON:
            return L("backup.error.invalid_json")
        case .missingMetadata:
            return L("backup.error.missing_metadata")
        case .newerSchemaVersion(let current, let file):
            return L("backup.error.newer_schema") + " (\(current) < \(file))"
        case .corruptedData:
            return L("backup.error.corrupted_data")
        }
    }
}
