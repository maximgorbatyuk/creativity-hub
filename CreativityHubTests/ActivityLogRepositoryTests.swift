import Foundation
import Testing
@testable import CreativityHub

struct ActivityLogRepositoryTests {
    private func setupWithProject() throws -> (TestDatabaseHelper, Project) {
        let helper = try TestDatabaseHelper()
        let project = createTestProject(name: "Activity Project")
        _ = helper.projectRepository.insert(project)
        return (helper, project)
    }

    @Test func insert_andFetchByProjectId_returnsLogsOrderedByDate() throws {
        let (helper, project) = try setupWithProject()
        let calendar = Calendar.current
        let now = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: now)!

        let oldLog = ActivityLog(
            projectId: project.id,
            entityType: .idea,
            actionType: .created,
            createdAt: yesterday
        )
        let recentLog = ActivityLog(
            projectId: project.id,
            entityType: .note,
            actionType: .updated,
            createdAt: now
        )

        _ = helper.activityLogRepository.insert(recentLog)
        _ = helper.activityLogRepository.insert(oldLog)

        let logs = helper.activityLogRepository.fetchByProjectId(projectId: project.id)

        #expect(logs.count == 2)
        #expect(logs.first?.entityType == .idea)
        #expect(logs.last?.entityType == .note)
    }

    @Test func fetchDailyCountsByProjectId_groupsByDayWithinRange() throws {
        let (helper, project) = try setupWithProject()
        let calendar = Calendar.current
        let baseDay = calendar.startOfDay(for: Date())
        let day1 = calendar.date(byAdding: .day, value: -2, to: baseDay)!
        let day2 = calendar.date(byAdding: .day, value: -1, to: baseDay)!

        _ = helper.activityLogRepository.insert(ActivityLog(projectId: project.id, entityType: .project, actionType: .created, createdAt: day1))
        _ = helper.activityLogRepository.insert(ActivityLog(projectId: project.id, entityType: .idea, actionType: .created, createdAt: day2))
        _ = helper.activityLogRepository.insert(ActivityLog(projectId: project.id, entityType: .idea, actionType: .updated, createdAt: day2))

        let counts = helper.activityLogRepository.fetchDailyCountsByProjectId(
            projectId: project.id,
            since: day1,
            until: day2
        )

        #expect(counts[day1] == 1)
        #expect(counts[day2] == 2)
        #expect(counts.count == 2)
    }

    @Test func deleteOlderThan_removesOnlyOldLogs() throws {
        let (helper, project) = try setupWithProject()
        let calendar = Calendar.current
        let now = calendar.startOfDay(for: Date())
        let oldDate = calendar.date(byAdding: .month, value: -7, to: now)!
        let recentDate = calendar.date(byAdding: .month, value: -1, to: now)!

        _ = helper.activityLogRepository.insert(ActivityLog(projectId: project.id, entityType: .project, actionType: .created, createdAt: oldDate))
        _ = helper.activityLogRepository.insert(ActivityLog(projectId: project.id, entityType: .project, actionType: .updated, createdAt: recentDate))

        let deleted = helper.activityLogRepository.deleteOlderThan(calendar.date(byAdding: .month, value: -6, to: now)!)
        let remainingLogs = helper.activityLogRepository.fetchByProjectId(projectId: project.id)

        #expect(deleted == 1)
        #expect(remainingLogs.count == 1)
        #expect(remainingLogs.first?.actionType == .updated)
    }

    @Test func deleteByProjectId_removesOnlyRequestedProjectLogs() throws {
        let (helper, project) = try setupWithProject()
        let otherProject = createTestProject(name: "Other Activity Project")
        _ = helper.projectRepository.insert(otherProject)

        _ = helper.activityLogRepository.insert(ActivityLog(projectId: project.id, entityType: .note, actionType: .created))
        _ = helper.activityLogRepository.insert(ActivityLog(projectId: otherProject.id, entityType: .note, actionType: .created))

        let deleted = helper.activityLogRepository.deleteByProjectId(projectId: project.id)

        #expect(deleted == true)
        #expect(helper.activityLogRepository.fetchByProjectId(projectId: project.id).isEmpty)
        #expect(helper.activityLogRepository.fetchByProjectId(projectId: otherProject.id).count == 1)
    }
}
