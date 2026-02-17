import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab(L("tab.today"), systemImage: "sun.max.fill", value: 0) {
                TodayView()
            }

            Tab(L("tab.projects"), systemImage: "folder.fill", value: 1) {
                ProjectsListView()
            }

            Tab(L("tab.search"), systemImage: "magnifyingglass", value: 2) {
                SearchView()
            }

            Tab(L("tab.settings"), systemImage: "gearshape.fill", value: 3) {
                UserSettingsView()
            }
        }
    }
}

#Preview {
    MainTabView()
}
