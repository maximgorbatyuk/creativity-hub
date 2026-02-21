import Foundation

struct WorkLog: Codable, Identifiable, Equatable, Hashable {
    let id: UUID
    let projectId: UUID
    var title: String?
    var linkedChecklistItemId: UUID?
    var totalMinutes: Int
    let createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        projectId: UUID,
        title: String? = nil,
        linkedChecklistItemId: UUID? = nil,
        totalMinutes: Int,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.projectId = projectId
        self.title = title
        self.linkedChecklistItemId = linkedChecklistItemId
        self.totalMinutes = totalMinutes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var formattedDuration: String {
        let days = totalMinutes / 1440
        let hours = (totalMinutes % 1440) / 60
        let minutes = totalMinutes % 60

        var parts: [String] = []
        if days > 0 { parts.append("\(days)d") }
        if hours > 0 { parts.append("\(hours)h") }
        if minutes > 0 || parts.isEmpty {
            parts.append("\(minutes)m")
        }
        return parts.joined(separator: " ")
    }
}
