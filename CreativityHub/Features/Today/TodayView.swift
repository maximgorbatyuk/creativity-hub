import SwiftUI

struct TodayView: View {
    var body: some View {
        NavigationStack {
            TypedEmptyStateView(
                type: .projects,
                actionTitle: L("today.create_project")
            ) {
                // Will navigate to project creation
            }
            .navigationTitle(L("tab.today"))
        }
    }
}

#Preview {
    TodayView()
}
