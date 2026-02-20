import SwiftUI

struct ProjectRowView: View {
    let project: Project
    var stats: ProjectRowStats?

    var body: some View {
        HStack(spacing: 12) {
            projectIcon
            projectInfo
            Spacer()
            trailingInfo
        }
        .padding(.vertical, 6)
    }

    // MARK: - Subviews

    private var projectIcon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(projectColor.opacity(0.15))
                .frame(width: 44, height: 44)

            Image(systemName: project.status.icon)
                .font(.title3)
                .foregroundColor(projectColor)
        }
    }

    private var projectInfo: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                if project.isPinned {
                    Image(systemName: "pin.fill")
                        .font(.caption2)
                        .foregroundColor(.orange)
                }
                Text(project.name)
                    .font(.headline)
                    .lineLimit(1)
            }

            if let description = project.projectDescription, !description.isEmpty {
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            HStack(spacing: 8) {
                statusBadge

                if let stats, stats.checklistProgress.total > 0 {
                    progressLabel(stats.checklistProgress)
                }

                if let stats, stats.reminderCount > 0 {
                    Label("\(stats.reminderCount)", systemImage: "bell")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    private var statusBadge: some View {
        Text(project.status.displayName)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(project.status.color.opacity(0.15))
            .foregroundColor(project.status.color)
            .cornerRadius(4)
    }

    private func progressLabel(_ progress: (checked: Int, total: Int)) -> some View {
        Label("\(progress.checked)/\(progress.total)", systemImage: "checklist")
            .font(.caption)
            .foregroundColor(progress.checked == progress.total ? .green : .secondary)
    }

    private var trailingInfo: some View {
        VStack(alignment: .trailing, spacing: 4) {
            if let formatted = project.formattedBudget {
                Text(formatted)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Helpers

    private var projectColor: Color {
        if let colorName = project.coverColor {
            return Color.fromProjectColor(colorName)
        }
        return project.status.color
    }
}

// MARK: - Project Color Mapping

extension Color {
    static func fromProjectColor(_ name: String) -> Color {
        switch name {
        case "red": return .red
        case "orange": return .orange
        case "yellow": return .yellow
        case "green": return .green
        case "blue": return .blue
        case "purple": return .purple
        case "pink": return .pink
        case "teal": return .teal
        case "indigo": return .indigo
        case "brown": return .brown
        default: return .blue
        }
    }

    static let projectColorOptions: [(name: String, color: Color)] = [
        ("red", .red),
        ("orange", .orange),
        ("yellow", .yellow),
        ("green", .green),
        ("blue", .blue),
        ("purple", .purple),
        ("pink", .pink),
        ("teal", .teal),
        ("indigo", .indigo),
        ("brown", .brown)
    ]
}

#Preview {
    List {
        ProjectRowView(project: Project(
            name: "Kitchen Renovation",
            projectDescription: "Complete remodel of the kitchen",
            coverColor: "blue",
            status: .active,
            startDate: Date(),
            targetDate: Date().addingTimeInterval(30 * 24 * 3600),
            budget: 5000,
            budgetCurrency: .usd,
            isPinned: true
        ))

        ProjectRowView(project: Project(
            name: "Birthday Party",
            status: .completed
        ))
    }
}
