import SwiftUI

struct ProjectsListView: View {
    var body: some View {
        NavigationStack {
            TypedEmptyStateView(type: .projects)
            .navigationTitle(L("tab.projects"))
        }
    }
}

#Preview {
    ProjectsListView()
}
