import SwiftUI

struct TodayView: View {
    var body: some View {
        NavigationStack {
            TypedEmptyStateView(type: .projects)
            .navigationTitle(L("tab.today"))
        }
    }
}

#Preview {
    TodayView()
}
