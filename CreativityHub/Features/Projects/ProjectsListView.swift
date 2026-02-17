import SwiftUI

struct ProjectsListView: View {
    var body: some View {
        NavigationStack {
            TypedEmptyStateView(
                type: .projects,
                actionTitle: L("projects.new")
            ) {
                // Will navigate to project creation
            }
            .navigationTitle(L("tab.projects"))
        }
    }
}

#Preview {
    ProjectsListView()
}
