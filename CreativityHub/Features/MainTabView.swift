import SwiftUI

struct MainTabView: View {
    private let viewModel = MainTabViewModel(
        appVersionChecker: AppVersionChecker(environment: EnvironmentService.shared)
    )

    @ObservedObject private var loc = LocalizationManager.shared
    @State private var selectedTab = 0
    @State private var showAppVersionBadge = false

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
                UserSettingsView(showAppUpdateButton: showAppVersionBadge)
            }
        }
        .id(loc.currentLanguage.rawValue)
        .onAppear {
            Task {
                let appVersionCheckResult = await viewModel.checkAppVersion()
                showAppVersionBadge = appVersionCheckResult ?? false
            }
        }
    }
}

#Preview {
    MainTabView()
}
