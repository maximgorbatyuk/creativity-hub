import Testing
import Foundation
@testable import CreativityHub

struct ReminderRepositoryTests {
    private func setupWithProject() throws -> (TestDatabaseHelper, Project) {
        let helper = try TestDatabaseHelper()
        let project = createTestProject(name: "Reminder Test Project")
        _ = helper.projectRepository.insert(project)
        return (helper, project)
    }

    @Test func insert_andFetchByProjectId_returnsReminders() throws {
        let (helper, project) = try setupWithProject()
        let reminder = createTestReminder(
            projectId: project.id,
            title: "Review draft",
            priority: .high
        )

        let result = helper.reminderRepository.insert(reminder)
        #expect(result == true)

        let reminders = helper.reminderRepository.fetchByProjectId(projectId: project.id)
        #expect(reminders.count == 1)
        #expect(reminders.first?.title == "Review draft")
        #expect(reminders.first?.priority == .high)
    }

    @Test func update_modifiesReminder() throws {
        let (helper, project) = try setupWithProject()
        var reminder = createTestReminder(projectId: project.id, title: "Original")
        _ = helper.reminderRepository.insert(reminder)

        reminder.title = "Updated"
        reminder.isCompleted = true
        let updated = helper.reminderRepository.update(reminder)
        #expect(updated == true)

        let reminders = helper.reminderRepository.fetchByProjectId(projectId: project.id)
        #expect(reminders.first?.title == "Updated")
        #expect(reminders.first?.isCompleted == true)
    }

    @Test func delete_removesReminder() throws {
        let (helper, project) = try setupWithProject()
        let reminder = createTestReminder(projectId: project.id, title: "To Delete")
        _ = helper.reminderRepository.insert(reminder)

        let deleted = helper.reminderRepository.delete(id: reminder.id)
        #expect(deleted == true)

        let reminders = helper.reminderRepository.fetchByProjectId(projectId: project.id)
        #expect(reminders.isEmpty)
    }

    @Test func deleteByProjectId_removesOnlyProjectReminders() throws {
        let (helper, project) = try setupWithProject()
        _ = helper.reminderRepository.insert(createTestReminder(projectId: project.id, title: "R1"))
        _ = helper.reminderRepository.insert(createTestReminder(projectId: project.id, title: "R2"))

        let otherProject = createTestProject(name: "Other")
        _ = helper.projectRepository.insert(otherProject)
        _ = helper.reminderRepository.insert(createTestReminder(projectId: otherProject.id, title: "Other R"))

        _ = helper.reminderRepository.deleteByProjectId(projectId: project.id)

        let projectReminders = helper.reminderRepository.fetchByProjectId(projectId: project.id)
        #expect(projectReminders.isEmpty)

        let otherReminders = helper.reminderRepository.fetchByProjectId(projectId: otherProject.id)
        #expect(otherReminders.count == 1)
    }

    @Test func fetchAll_returnsAllReminders() throws {
        let (helper, project) = try setupWithProject()
        _ = helper.reminderRepository.insert(createTestReminder(projectId: project.id, title: "A"))
        _ = helper.reminderRepository.insert(createTestReminder(projectId: project.id, title: "B"))

        let all = helper.reminderRepository.fetchAll()
        #expect(all.count == 2)
    }

    @Test func insert_withDueDate_preservesDate() throws {
        let (helper, project) = try setupWithProject()
        let dueDate = Calendar.current.date(byAdding: .day, value: 3, to: Date())!
        let reminder = createTestReminder(
            projectId: project.id,
            title: "Due Soon",
            dueDate: dueDate
        )

        _ = helper.reminderRepository.insert(reminder)

        let fetched = helper.reminderRepository.fetchByProjectId(projectId: project.id)
        #expect(fetched.first?.dueDate != nil)
    }

    @Test func fetchUpcoming_excludesOverdueAndNoDueDate() throws {
        let (helper, project) = try setupWithProject()

        let overdue = createTestReminder(
            projectId: project.id,
            title: "Overdue",
            dueDate: Calendar.current.date(byAdding: .day, value: -1, to: Date())
        )

        let upcoming = createTestReminder(
            projectId: project.id,
            title: "Upcoming",
            dueDate: Calendar.current.date(byAdding: .day, value: 2, to: Date())
        )

        let noDueDate = createTestReminder(
            projectId: project.id,
            title: "No Due Date",
            dueDate: nil
        )

        _ = helper.reminderRepository.insert(overdue)
        _ = helper.reminderRepository.insert(upcoming)
        _ = helper.reminderRepository.insert(noDueDate)

        let upcomingItems = helper.reminderRepository.fetchUpcoming(limit: 10)

        #expect(upcomingItems.count == 1)
        #expect(upcomingItems.first?.title == "Upcoming")
    }
}
