import Testing
@testable import CreativityHub

struct ProjectRepositoryTests {
    @Test func insert_andFetchById_returnsProject() throws {
        let helper = try TestDatabaseHelper()
        let project = createTestProject(name: "My Creative Project")

        let result = helper.projectRepository.insert(project)

        #expect(result == true)

        let fetched = helper.projectRepository.fetchById(id: project.id)
        #expect(fetched != nil)
        #expect(fetched?.name == "My Creative Project")
        #expect(fetched?.status == .active)
    }

    @Test func fetchAll_returnsAllProjects() throws {
        let helper = try TestDatabaseHelper()
        let project1 = createTestProject(name: "Project A")
        let project2 = createTestProject(name: "Project B")

        _ = helper.projectRepository.insert(project1)
        _ = helper.projectRepository.insert(project2)

        let all = helper.projectRepository.fetchAll()
        #expect(all.count == 2)
    }

    @Test func fetchAll_returnsPinnedFirst() throws {
        let helper = try TestDatabaseHelper()
        let regular = createTestProject(name: "Regular", isPinned: false)
        let pinned = createTestProject(name: "Pinned", isPinned: true)

        _ = helper.projectRepository.insert(regular)
        _ = helper.projectRepository.insert(pinned)

        let all = helper.projectRepository.fetchAll()
        #expect(all.first?.name == "Pinned")
    }

    @Test func update_modifiesProject() throws {
        let helper = try TestDatabaseHelper()
        var project = createTestProject(name: "Original")
        _ = helper.projectRepository.insert(project)

        project.name = "Updated"
        project.status = .completed
        let updated = helper.projectRepository.update(project)

        #expect(updated == true)

        let fetched = helper.projectRepository.fetchById(id: project.id)
        #expect(fetched?.name == "Updated")
        #expect(fetched?.status == .completed)
    }

    @Test func delete_removesProject() throws {
        let helper = try TestDatabaseHelper()
        let project = createTestProject(name: "To Delete")
        _ = helper.projectRepository.insert(project)

        let deleted = helper.projectRepository.delete(id: project.id)

        #expect(deleted == true)

        let fetched = helper.projectRepository.fetchById(id: project.id)
        #expect(fetched == nil)
    }

    @Test func fetchByStatus_filtersCorrectly() throws {
        let helper = try TestDatabaseHelper()
        let active = createTestProject(name: "Active", status: .active)
        let completed = createTestProject(name: "Completed", status: .completed)
        let archived = createTestProject(name: "Archived", status: .archived)

        _ = helper.projectRepository.insert(active)
        _ = helper.projectRepository.insert(completed)
        _ = helper.projectRepository.insert(archived)

        let activeProjects = helper.projectRepository.fetchByStatus(.active)
        #expect(activeProjects.count == 1)
        #expect(activeProjects.first?.name == "Active")

        let completedProjects = helper.projectRepository.fetchByStatus(.completed)
        #expect(completedProjects.count == 1)
    }

    @Test func search_findsMatchingProjects() throws {
        let helper = try TestDatabaseHelper()
        let project1 = createTestProject(name: "Logo Design")
        let project2 = createTestProject(name: "Website Redesign")
        let project3 = createTestProject(name: "Photography")

        _ = helper.projectRepository.insert(project1)
        _ = helper.projectRepository.insert(project2)
        _ = helper.projectRepository.insert(project3)

        let results = helper.projectRepository.search(query: "design")
        #expect(results.count == 2)
    }

    @Test func togglePin_updatesPinState() throws {
        let helper = try TestDatabaseHelper()
        let project = createTestProject(name: "Pin Me", isPinned: false)
        _ = helper.projectRepository.insert(project)

        _ = helper.projectRepository.togglePin(id: project.id, isPinned: true)

        let fetched = helper.projectRepository.fetchById(id: project.id)
        #expect(fetched?.isPinned == true)
    }

    @Test func count_returnsCorrectNumber() throws {
        let helper = try TestDatabaseHelper()

        #expect(helper.projectRepository.count() == 0)

        _ = helper.projectRepository.insert(createTestProject(name: "One"))
        _ = helper.projectRepository.insert(createTestProject(name: "Two"))

        #expect(helper.projectRepository.count() == 2)
    }

    @Test func deleteAll_removesAllProjects() throws {
        let helper = try TestDatabaseHelper()
        _ = helper.projectRepository.insert(createTestProject(name: "A"))
        _ = helper.projectRepository.insert(createTestProject(name: "B"))

        helper.projectRepository.deleteAll()

        #expect(helper.projectRepository.count() == 0)
    }
}
