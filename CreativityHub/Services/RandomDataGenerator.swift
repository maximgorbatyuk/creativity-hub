import Foundation
import os

class RandomDataGenerator {
    private let db: DatabaseManager
    private let logger: Logger

    init(db: DatabaseManager = .shared) {
        self.db = db
        self.logger = Logger(
            subsystem: Bundle.main.bundleIdentifier ?? "-",
            category: "RandomDataGenerator"
        )
    }

    // MARK: - Main Generation

    func generateRandomData(for project: Project) {
        logger.info("Starting random data generation for project: \(project.name)")

        deleteExistingData(for: project.id)

        let checklists = generateChecklists(for: project)
        for (checklist, items) in checklists {
            _ = db.checklistRepository?.insert(checklist)
            items.forEach { _ = db.checklistItemRepository?.insert($0) }
        }

        let ideas = generateIdeas(for: project)
        ideas.forEach { _ = db.ideaRepository?.insert($0) }

        let tags = generateTags()
        tags.forEach { _ = db.tagRepository?.insert($0) }

        // Link some tags to ideas
        for idea in ideas {
            let tagCount = Int.random(in: 0...2)
            let selectedTags = tags.shuffled().prefix(tagCount)
            for tag in selectedTags {
                _ = db.tagRepository?.linkTagToIdea(tagId: tag.id, ideaId: idea.id)
            }
        }

        let categories = generateExpenseCategories(for: project)
        categories.forEach { _ = db.expenseCategoryRepository?.insert($0) }

        let expenses = generateExpenses(for: project, categories: categories)
        expenses.forEach { _ = db.expenseRepository?.insert($0) }

        let notes = generateNotes(for: project)
        notes.forEach { _ = db.noteRepository?.insert($0) }

        let reminders = generateReminders(for: project)
        reminders.forEach { _ = db.reminderRepository?.insert($0) }

        let workLogs = generateWorkLogs(for: project)
        workLogs.forEach { _ = db.workLogRepository?.insert($0) }

        logger.info("Random data generation completed for project: \(project.name)")
    }

    // MARK: - Delete Existing Data

    private func deleteExistingData(for projectId: UUID) {
        _ = db.workLogRepository?.deleteByProjectId(projectId: projectId)
        _ = db.reminderRepository?.deleteByProjectId(projectId: projectId)
        _ = db.noteRepository?.deleteByProjectId(projectId: projectId)
        _ = db.expenseRepository?.deleteByProjectId(projectId: projectId)
        _ = db.expenseCategoryRepository?.deleteByProjectId(projectId: projectId)
        _ = db.documentRepository?.deleteByProjectId(projectId: projectId)

        let checklists = db.checklistRepository?.fetchByProjectId(projectId: projectId) ?? []
        for checklist in checklists {
            _ = db.checklistItemRepository?.deleteByChecklistId(checklistId: checklist.id)
        }
        _ = db.checklistRepository?.deleteByProjectId(projectId: projectId)

        let ideas = db.ideaRepository?.fetchByProjectId(projectId: projectId) ?? []
        for idea in ideas {
            _ = db.tagRepository?.deleteLinksForIdea(ideaId: idea.id)
        }
        _ = db.ideaRepository?.deleteByProjectId(projectId: projectId)
    }

    // MARK: - Checklists

    private func generateChecklists(for project: Project) -> [(checklist: Checklist, items: [ChecklistItem])] {
        var result: [(checklist: Checklist, items: [ChecklistItem])] = []

        let checklistData: [(String, [String])] = [
            ("Research & Planning", ["Define project scope", "Research competitors", "Create mood board", "Gather reference materials", "Set milestones", "Identify tools needed", "Budget estimation"]),
            ("Materials & Supplies", ["Canvas or paper", "Paints and brushes", "Digital software license", "Storage containers", "Reference books", "Measuring tools", "Protective equipment"]),
            ("Tasks To Do", ["Draft initial concept", "Review feedback", "Make revisions", "Final review", "Export deliverables", "Archive project files", "Send to client"]),
            ("Pre-Launch Checklist", ["Quality check", "Spell check all text", "Test on multiple devices", "Prepare promotional materials", "Set up analytics", "Notify stakeholders"])
        ]

        let selected = checklistData.shuffled().prefix(3)

        for (index, (name, itemNames)) in selected.enumerated() {
            let checklist = Checklist(
                projectId: project.id,
                name: name,
                sortOrder: index
            )

            let itemCount = Int.random(in: 4...min(7, itemNames.count))
            let selectedItems = itemNames.shuffled().prefix(itemCount)

            var items: [ChecklistItem] = []
            for (itemIndex, itemName) in selectedItems.enumerated() {
                let isCompleted = Double.random(in: 0...1) < 0.35
                let hasDueDate = Double.random(in: 0...1) < 0.4
                let hasCost = Double.random(in: 0...1) < 0.3

                var dueDate: Date?
                if hasDueDate {
                    let dayOffset = Int.random(in: -5...30)
                    dueDate = Calendar.current.date(byAdding: .day, value: dayOffset, to: Date())
                }

                let priorities: [ItemPriority] = [.none, .none, .low, .medium, .high]

                let item = ChecklistItem(
                    checklistId: checklist.id,
                    name: itemName,
                    isCompleted: isCompleted,
                    dueDate: dueDate,
                    priority: priorities.randomElement() ?? .none,
                    estimatedCost: hasCost ? Decimal(Int.random(in: 5...200)) : nil,
                    estimatedCostCurrency: hasCost ? .usd : nil,
                    sortOrder: itemIndex
                )
                items.append(item)
            }

            result.append((checklist: checklist, items: items))
        }

        return result
    }

    // MARK: - Ideas

    private func generateIdeas(for project: Project) -> [Idea] {
        let ideaData: [(String, IdeaSourceType, String?, String?)] = [
            ("Color palette inspiration", .pinterest, "https://pinterest.com/pin/example1", "Warm earth tones with accent blue"),
            ("Typography reference", .website, "https://fonts.google.com", "Consider using Inter or Poppins"),
            ("Competitor analysis video", .youtube, "https://youtube.com/watch?v=example2", "Great breakdown of industry trends"),
            ("Design trend 2026", .instagram, "https://instagram.com/p/example3", nil),
            ("Minimalist approach examples", .website, "https://dribbble.com/shots/example4", "Less is more — focus on whitespace"),
            ("Brand identity case study", .youtube, "https://youtube.com/watch?v=example5", "Step-by-step rebranding process"),
            ("Texture patterns collection", .pinterest, "https://pinterest.com/pin/example6", nil),
            ("Client brief examples", .other, nil, "Review how other agencies structure their briefs"),
            ("Material sourcing guide", .website, "https://example.com/materials", "Sustainable and eco-friendly options"),
            ("Community feedback thread", .other, nil, "Useful insights from Reddit design community")
        ]

        let count = Int.random(in: 4...6)
        var ideas: [Idea] = []
        var usedIndices: Set<Int> = []

        for _ in 0..<count {
            var index: Int
            repeat {
                index = Int.random(in: 0..<ideaData.count)
            } while usedIndices.contains(index)
            usedIndices.insert(index)

            let (title, sourceType, url, notes) = ideaData[index]

            let idea = Idea(
                projectId: project.id,
                url: url,
                title: title,
                sourceDomain: url.flatMap { URL(string: $0)?.host },
                sourceType: sourceType,
                notes: notes
            )
            ideas.append(idea)
        }

        return ideas
    }

    // MARK: - Tags

    private func generateTags() -> [Tag] {
        let tagData: [(String, String)] = [
            ("Design", "blue"),
            ("Research", "green"),
            ("Urgent", "red"),
            ("Inspiration", "purple"),
            ("Budget", "orange"),
            ("Reference", "teal")
        ]

        return tagData.shuffled().prefix(4).map { name, color in
            Tag(name: name, color: color)
        }
    }

    // MARK: - Expense Categories

    private func generateExpenseCategories(for project: Project) -> [ExpenseCategory] {
        let categoryData: [(String, String)] = [
            ("Materials", "blue"),
            ("Software", "purple"),
            ("Equipment", "green"),
            ("Outsourcing", "orange"),
            ("Marketing", "red")
        ]

        return categoryData.prefix(3).enumerated().map { index, element in
            let (name, color) = element
            return ExpenseCategory(
                projectId: project.id,
                name: name,
                budgetLimit: Decimal(Int.random(in: 100...500)),
                budgetCurrency: .usd,
                color: color,
                sortOrder: index
            )
        }
    }

    // MARK: - Expenses

    private func generateExpenses(for project: Project, categories: [ExpenseCategory]) -> [Expense] {
        let vendors = ["Amazon", "Adobe", "Canva", "Shutterstock", "Figma", "Local Supply Store", "Freelancer.com", "Etsy"]
        let count = Int.random(in: 5...8)

        return (0..<count).map { _ in
            let statuses: [ExpenseStatus] = [.paid, .paid, .planned, .planned, .refunded]

            return Expense(
                projectId: project.id,
                categoryId: categories.randomElement()?.id,
                amount: Decimal(Int.random(in: 10...300)),
                currency: .usd,
                date: Calendar.current.date(byAdding: .day, value: Int.random(in: -30...0), to: Date()) ?? Date(),
                vendor: vendors.randomElement(),
                status: statuses.randomElement() ?? .planned
            )
        }
    }

    // MARK: - Notes

    private func generateNotes(for project: Project) -> [Note] {
        let noteData: [(String, String)] = [
            ("Project Brief", "Objective: Create a cohesive visual identity.\n\nTarget audience: Young professionals aged 25-35.\n\nDeliverables:\n- Logo variations\n- Color palette\n- Typography guide\n- Social media templates"),
            ("Meeting Notes", "Key decisions from today's meeting:\n1. Go with option B for the layout\n2. Deadline extended by one week\n3. Need feedback from stakeholders by Friday\n4. Schedule review session next Tuesday"),
            ("Inspiration & References", "Styles to explore:\n- Scandinavian minimalism\n- Japanese wabi-sabi\n- Bauhaus geometry\n\nColor inspiration: sunrise palette, ocean blues"),
            ("Budget Breakdown", "Materials: $200\nSoftware: $50/month\nPrinting: $150\nContingency: $100\n\nTotal estimated: $500"),
            ("Feedback Log", "Round 1: Client loved the direction, wants more contrast.\nRound 2: Approved with minor tweaks to typography.\nFinal: Signed off!")
        ]

        let count = Int.random(in: 3...4)
        var notes: [Note] = []
        var usedIndices: Set<Int> = []

        for i in 0..<count {
            var index: Int
            repeat {
                index = Int.random(in: 0..<noteData.count)
            } while usedIndices.contains(index)
            usedIndices.insert(index)

            let (title, content) = noteData[index]
            let note = Note(
                projectId: project.id,
                title: title,
                content: content,
                isPinned: i == 0,
                sortOrder: i
            )
            notes.append(note)
        }

        return notes
    }

    // MARK: - Work Logs

    private func generateWorkLogs(for project: Project) -> [WorkLog] {
        let titles = [
            "Research and brainstorming",
            "Design iteration",
            "Client feedback review",
            "Material preparation",
            "Sketching concepts",
            "Documentation update",
            nil, nil, nil
        ]
        let count = Int.random(in: 3...6)

        return (0..<count).map { _ in
            let days = Int.random(in: 0...2)
            let hours = Int.random(in: 0...8)
            let minutes = [0, 15, 30, 45].randomElement() ?? 0
            let totalMinutes = days * 1440 + hours * 60 + minutes
            let validTotal = max(totalMinutes, 15)

            let dayOffset = Int.random(in: -14...0)
            let createdAt = Calendar.current.date(byAdding: .day, value: dayOffset, to: Date()) ?? Date()

            return WorkLog(
                projectId: project.id,
                title: titles.randomElement() ?? nil,
                totalMinutes: validTotal,
                createdAt: createdAt,
                updatedAt: createdAt
            )
        }
    }

    // MARK: - Reminders

    private func generateReminders(for project: Project) -> [Reminder] {
        let reminderData: [(String, String?, Int, ItemPriority)] = [
            ("Submit draft for review", "Send to stakeholders via email", -2, .high),
            ("Order supplies", "Check the materials list first", 1, .medium),
            ("Schedule team sync", nil, 3, .low),
            ("Update project timeline", "Reflect the new deadline", 5, .medium),
            ("Review competitor analysis", "Compare with our approach", 7, .low),
            ("Prepare presentation", "Include progress photos and metrics", 10, .high),
            ("Follow up with client", nil, 14, .medium),
            ("Archive completed materials", "Move to shared drive", 21, .none)
        ]

        let count = Int.random(in: 4...6)
        var reminders: [Reminder] = []
        var usedIndices: Set<Int> = []

        for _ in 0..<count {
            var index: Int
            repeat {
                index = Int.random(in: 0..<reminderData.count)
            } while usedIndices.contains(index)
            usedIndices.insert(index)

            let (title, notes, dayOffset, priority) = reminderData[index]
            let dueDate = Calendar.current.date(byAdding: .day, value: dayOffset, to: Date())
            let isCompleted = dayOffset < 0 && Double.random(in: 0...1) < 0.6

            let reminder = Reminder(
                projectId: project.id,
                title: title,
                notes: notes,
                dueDate: dueDate,
                isCompleted: isCompleted,
                priority: priority
            )
            reminders.append(reminder)
        }

        return reminders
    }
}
