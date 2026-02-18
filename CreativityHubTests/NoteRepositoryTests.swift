import Testing
@testable import CreativityHub

struct NoteRepositoryTests {
    private func setupWithProject() throws -> (TestDatabaseHelper, Project) {
        let helper = try TestDatabaseHelper()
        let project = createTestProject(name: "Note Test Project")
        _ = helper.projectRepository.insert(project)
        return (helper, project)
    }

    @Test func insert_andFetchByProjectId_returnsNotes() throws {
        let (helper, project) = try setupWithProject()
        let note = createTestNote(projectId: project.id, title: "My Note", content: "Some content")

        let result = helper.noteRepository.insert(note)
        #expect(result == true)

        let notes = helper.noteRepository.fetchByProjectId(projectId: project.id)
        #expect(notes.count == 1)
        #expect(notes.first?.title == "My Note")
        #expect(notes.first?.content == "Some content")
    }

    @Test func fetchByProjectId_returnsPinnedFirst() throws {
        let (helper, project) = try setupWithProject()
        let regular = createTestNote(projectId: project.id, title: "Regular", isPinned: false)
        let pinned = createTestNote(projectId: project.id, title: "Pinned", isPinned: true)

        _ = helper.noteRepository.insert(regular)
        _ = helper.noteRepository.insert(pinned)

        let notes = helper.noteRepository.fetchByProjectId(projectId: project.id)
        #expect(notes.first?.title == "Pinned")
    }

    @Test func update_modifiesNote() throws {
        let (helper, project) = try setupWithProject()
        var note = createTestNote(projectId: project.id, title: "Original")
        _ = helper.noteRepository.insert(note)

        note.title = "Updated Title"
        note.content = "Updated content"
        let updated = helper.noteRepository.update(note)
        #expect(updated == true)

        let notes = helper.noteRepository.fetchByProjectId(projectId: project.id)
        #expect(notes.first?.title == "Updated Title")
        #expect(notes.first?.content == "Updated content")
    }

    @Test func delete_removesNote() throws {
        let (helper, project) = try setupWithProject()
        let note = createTestNote(projectId: project.id, title: "To Delete")
        _ = helper.noteRepository.insert(note)

        let deleted = helper.noteRepository.delete(id: note.id)
        #expect(deleted == true)

        let notes = helper.noteRepository.fetchByProjectId(projectId: project.id)
        #expect(notes.isEmpty)
    }

    @Test func deleteByProjectId_removesAllNotesForProject() throws {
        let (helper, project) = try setupWithProject()
        _ = helper.noteRepository.insert(createTestNote(projectId: project.id, title: "Note 1"))
        _ = helper.noteRepository.insert(createTestNote(projectId: project.id, title: "Note 2"))

        let otherProject = createTestProject(name: "Other Project")
        _ = helper.projectRepository.insert(otherProject)
        _ = helper.noteRepository.insert(createTestNote(projectId: otherProject.id, title: "Other Note"))

        _ = helper.noteRepository.deleteByProjectId(projectId: project.id)

        let projectNotes = helper.noteRepository.fetchByProjectId(projectId: project.id)
        #expect(projectNotes.isEmpty)

        let otherNotes = helper.noteRepository.fetchByProjectId(projectId: otherProject.id)
        #expect(otherNotes.count == 1)
    }

    @Test func fetchAll_returnsAllNotes() throws {
        let (helper, project) = try setupWithProject()
        _ = helper.noteRepository.insert(createTestNote(projectId: project.id, title: "A"))
        _ = helper.noteRepository.insert(createTestNote(projectId: project.id, title: "B"))

        let all = helper.noteRepository.fetchAll()
        #expect(all.count == 2)
    }
}
