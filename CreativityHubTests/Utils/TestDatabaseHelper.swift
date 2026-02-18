import Foundation
import SQLite
@testable import CreativityHub

struct TestDatabaseHelper {
    let db: Connection
    let projectRepository: ProjectRepository
    let checklistRepository: ChecklistRepository
    let checklistItemRepository: ChecklistItemRepository
    let ideaRepository: IdeaRepository
    let tagRepository: TagRepository
    let expenseRepository: ExpenseRepository
    let expenseCategoryRepository: ExpenseCategoryRepository
    let noteRepository: NoteRepository
    let documentRepository: DocumentRepository
    let reminderRepository: ReminderRepository
    let userSettingsRepository: UserSettingsRepository

    init() throws {
        db = try Connection(.inMemory)

        // Migration v1: user_settings table
        userSettingsRepository = UserSettingsRepository(db: db)
        userSettingsRepository.createTable()
        _ = userSettingsRepository.upsertCurrency(Currency.usd.rawValue)

        // Migration v2: initial schema
        try Migration_20260217_InitialSchema(db: db).execute()

        // Migration v3: documents table
        try Migration_20260218_AddDocumentsTable(db: db).execute()

        // Migration v4: reminders table
        try Migration_20260218_AddRemindersTable(db: db).execute()

        // Initialize repositories
        projectRepository = ProjectRepository(db: db)
        checklistRepository = ChecklistRepository(db: db)
        checklistItemRepository = ChecklistItemRepository(db: db)
        ideaRepository = IdeaRepository(db: db)
        tagRepository = TagRepository(db: db)
        expenseRepository = ExpenseRepository(db: db)
        expenseCategoryRepository = ExpenseCategoryRepository(db: db)
        noteRepository = NoteRepository(db: db)
        documentRepository = DocumentRepository(db: db)
        reminderRepository = ReminderRepository(db: db)
    }
}
