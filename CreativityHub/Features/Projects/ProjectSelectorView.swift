import SwiftUI

struct ProjectSelectorView: View {
    let projects: [Project]
    let selectedProjectId: UUID?
    let onSelect: (UUID) -> Void
    let onCreateNew: () -> Void

    @State private var isExpanded: Bool = false

    private var selectedProject: Project? {
        projects.first(where: { $0.id == selectedProjectId })
    }

    var body: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    if let project = selectedProject {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(project.name)
                                .font(.headline)
                                .foregroundColor(.primary)

                            HStack(spacing: 8) {
                                HStack(spacing: 4) {
                                    Image(systemName: project.status.icon)
                                        .font(.caption)
                                    Text(project.status.displayName)
                                        .font(.caption)
                                        .foregroundColor(project.status.color)
                                }

                                if let description = project.projectDescription, !description.isEmpty {
                                    Text("•")
                                        .font(.caption)
                                    Text(description)
                                        .font(.caption)
                                        .lineLimit(1)
                                }
                            }
                            .foregroundColor(.secondary)
                        }
                    } else {
                        Text(L("project.selector.select_project"))
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemBackground))
            }
            .buttonStyle(.plain)

            if isExpanded {
                Divider()

                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(projects) { project in
                            ProjectSelectorRow(
                                project: project,
                                isSelected: project.id == selectedProjectId
                            ) {
                                onSelect(project.id)
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    isExpanded = false
                                }
                            }

                            if project.id != projects.last?.id {
                                Divider()
                                    .padding(.leading, 16)
                            }
                        }

                        Divider()

                        Button {
                            onCreateNew()
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isExpanded = false
                            }
                        } label: {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(.accentColor)
                                Text(L("project.selector.create_new"))
                                    .foregroundColor(.accentColor)
                                Spacer()
                            }
                            .padding()
                        }
                        .buttonStyle(.plain)
                    }
                }
                .frame(maxHeight: 300)
                .background(Color(.systemBackground))
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Selector Row

struct ProjectSelectorRow: View {
    let project: Project
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Circle()
                    .fill(project.status.color)
                    .frame(width: 8, height: 8)

                VStack(alignment: .leading, spacing: 2) {
                    Text(project.name)
                        .font(.subheadline)
                        .fontWeight(isSelected ? .semibold : .regular)
                        .foregroundColor(.primary)

                    HStack(spacing: 4) {
                        Text(project.status.displayName)
                            .foregroundColor(project.status.color)

                        if let description = project.projectDescription, !description.isEmpty {
                            Text("•")
                            Text(description)
                                .lineLimit(1)
                        }
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundColor(.accentColor)
                        .font(.body)
                }
            }
            .padding()
            .background(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
        }
        .buttonStyle(.plain)
    }
}
