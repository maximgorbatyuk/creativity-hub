import SwiftUI

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text(title)
                .font(.title3)
                .fontWeight(.semibold)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .fontWeight(.medium)
                }
                .buttonStyle(.borderedProminent)
                .padding(.top, 8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

enum EmptyStateType {
    case projects
    case checklists
    case checklistItems
    case ideas
    case expenses
    case notes
    case documents
    case reminders
    case searchResults

    var icon: String {
        switch self {
        case .projects: return "folder"
        case .checklists: return "checklist"
        case .checklistItems: return "checkmark.circle"
        case .ideas: return "lightbulb"
        case .expenses: return "creditcard"
        case .notes: return "note.text"
        case .documents: return "doc.fill"
        case .reminders: return "bell.fill"
        case .searchResults: return "magnifyingglass"
        }
    }

    var title: String {
        switch self {
        case .projects: return L("empty.projects.title")
        case .checklists: return L("empty.checklists.title")
        case .checklistItems: return L("empty.checklist_items.title")
        case .ideas: return L("empty.ideas.title")
        case .expenses: return L("empty.expenses.title")
        case .notes: return L("empty.notes.title")
        case .documents: return L("empty.documents.title")
        case .reminders: return L("empty.reminders.title")
        case .searchResults: return L("empty.search.title")
        }
    }

    var message: String {
        switch self {
        case .projects: return L("empty.projects.message")
        case .checklists: return L("empty.checklists.message")
        case .checklistItems: return L("empty.checklist_items.message")
        case .ideas: return L("empty.ideas.message")
        case .expenses: return L("empty.expenses.message")
        case .notes: return L("empty.notes.message")
        case .documents: return L("empty.documents.message")
        case .reminders: return L("empty.reminders.message")
        case .searchResults: return L("empty.search.message")
        }
    }
}

struct TypedEmptyStateView: View {
    let type: EmptyStateType
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        EmptyStateView(
            icon: type.icon,
            title: type.title,
            message: type.message,
            actionTitle: actionTitle,
            action: action
        )
    }
}

#Preview {
    TypedEmptyStateView(
        type: .projects,
        actionTitle: "Create Project"
    ) {}
}
