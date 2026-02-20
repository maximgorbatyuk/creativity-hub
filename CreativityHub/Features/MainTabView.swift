import SwiftUI

struct MainTabView: View {
    @ObservedObject private var loc = LocalizationManager.shared
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab(L("tab.home"), systemImage: "house.fill", value: 0) {
                TodayView()
            }

            Tab(L("tab.active_project"), systemImage: "folder.fill", value: 1) {
                ProjectContentView()
            }

            Tab(L("tab.projects_list"), systemImage: "list.bullet.rectangle", value: 2) {
                ProjectsListView()
            }

            Tab(L("tab.settings"), systemImage: "gearshape.fill", value: 3) {
                UserSettingsView()
            }
        }
        .id(loc.currentLanguage.rawValue)
    }
}

#Preview {
    MainTabView()
}
